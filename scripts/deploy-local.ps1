<#
.SYNOPSIS
  Build, load and deploy FinQuest to the local Kubernetes cluster.

.DESCRIPTION
  This script exists because "build the image and restart the deployment" does
  not work here, and fails *silently*. The node runs its own containerd with
  its own copy of every image; a rebuild under an unchanged tag never reaches
  it, and `imagePullPolicy: IfNotPresent` tells the kubelet the tag is already
  present, so the pod comes back running the previous build. Nothing errors.

  The fix is three things together, and none of them works alone:
    1. tag every build with the commit it came from, so a tag names one image
    2. load that image into the node explicitly
    3. `imagePullPolicy: Never`, so a missing image fails loudly instead of
       falling back to whatever the node happens to have cached

.EXAMPLE
  powershell -File scripts\deploy-local.ps1
  powershell -File scripts\deploy-local.ps1 -BackendOnly
#>
[CmdletBinding()]
param(
    [switch]$BackendOnly,
    [switch]$FrontendOnly
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$buildBackend  = -not $FrontendOnly
$buildFrontend = -not $BackendOnly

function Invoke-Checked {
    param([string]$What, [scriptblock]$Action)
    & $Action
    if ($LASTEXITCODE -ne 0) { throw "$What failed (exit $LASTEXITCODE)" }
}

# ── The tag ────────────────────────────────────────────────────────────────
# The commit identifies the source, but an uncommitted edit does not move
# HEAD — and deploying uncommitted work is the normal case while developing.
# A timestamp suffix keeps each dirty build distinct, so the tag never lies
# about which bytes are running.
$tag = (git rev-parse --short HEAD).Trim()
git diff --quiet HEAD -- backend frontend k8s
if ($LASTEXITCODE -ne 0) {
    $tag = "$tag-dirty.$(Get-Date -Format 'HHmmss')"
}
Write-Host "==> tag: $tag"

# ── The node ───────────────────────────────────────────────────────────────
$node = (kubectl get nodes -o jsonpath='{.items[0].metadata.name}').Trim()
Write-Host "==> node: $node"

function Import-ImageToNode {
    param([string]$Image)

    $kind = Get-Command kind -ErrorAction SilentlyContinue
    if ($kind) {
        $clusters = (kind get clusters 2>$null)
        if ($clusters) {
            Invoke-Checked "kind load $Image" { kind load docker-image $Image }
            return
        }
    }
    # Docker Desktop's Kubernetes node is a container running containerd.
    # Import into the k8s.io namespace, the one the kubelet reads.
    $tar = Join-Path ([System.IO.Path]::GetTempPath()) "finquest-$([guid]::NewGuid()).tar"
    try {
        Invoke-Checked "docker save $Image" { docker save $Image -o $tar }
        Invoke-Checked "ctr import $Image" {
            Get-Content -LiteralPath $tar -AsByteStream -Raw |
                docker exec -i $node ctr -n k8s.io images import --all-platforms -
        }
    }
    finally {
        if (Test-Path $tar) { Remove-Item $tar -Force }
    }
}

# ── Build + load ───────────────────────────────────────────────────────────
if ($buildBackend) {
    Write-Host "==> building finquest-backend:$tag"
    Invoke-Checked 'backend build' { docker build -q -t "finquest-backend:$tag" ./backend }
    Write-Host "==> loading finquest-backend:$tag into $node"
    Import-ImageToNode "finquest-backend:$tag"
}

if ($buildFrontend) {
    Write-Host "==> building finquest-frontend:$tag"
    # API_BASE_URL is compiled into the JS: it must be reachable from the
    # browser, never an in-cluster Service name.
    Invoke-Checked 'frontend build' {
        docker build -q -t "finquest-frontend:$tag" `
            --build-arg API_BASE_URL=http://localhost:8000 ./frontend
    }
    Write-Host "==> loading finquest-frontend:$tag into $node"
    Import-ImageToNode "finquest-frontend:$tag"
}

# ── Apply ──────────────────────────────────────────────────────────────────
if (-not (Test-Path 'k8s/secret.yaml')) {
    throw 'k8s/secret.yaml is missing - run: powershell -File k8s\scripts\gen-secret.ps1'
}

# Rendered into a temp directory rather than edited in place, so the manifests
# in git stay declarative and no deploy ever leaves a modified tree behind.
# Only k8s/*.yaml is copied: k8s/examples/ holds the placeholder Secret and
# must never reach a cluster.
# A component that was not rebuilt keeps the tag it is already running. Without
# this, -BackendOnly would point the frontend Deployment at a tag that was never
# built, and `imagePullPolicy: Never` would (correctly, loudly) fail it with
# ErrImageNeverPull.
function Resolve-DeployedTag {
    param([string]$Deployment)
    $image = kubectl get "deployment/$Deployment" `
        -o jsonpath='{.spec.template.spec.containers[0].image}' 2>$null
    $found = if ($image) { ($image -split ':')[-1] } else { '' }
    if (-not $found -or $found -eq 'UNSET') {
        throw "$Deployment is not deployed yet - run a full deploy first"
    }
    return $found
}

$backendTag  = $tag
$frontendTag = $tag
if (-not $buildBackend) {
    $backendTag = Resolve-DeployedTag 'backend'
    Write-Host "==> keeping backend at its running tag: $backendTag"
}
if (-not $buildFrontend) {
    $frontendTag = Resolve-DeployedTag 'frontend'
    Write-Host "==> keeping frontend at its running tag: $frontendTag"
}

$render = Join-Path ([System.IO.Path]::GetTempPath()) "finquest-manifests-$([guid]::NewGuid())"
New-Item -ItemType Directory -Path $render | Out-Null
try {
    foreach ($file in Get-ChildItem 'k8s/*.yaml') {
        (Get-Content -LiteralPath $file.FullName -Raw).
            Replace('finquest-backend:UNSET',  "finquest-backend:$backendTag").
            Replace('finquest-frontend:UNSET', "finquest-frontend:$frontendTag") |
            Set-Content -LiteralPath (Join-Path $render $file.Name) -Encoding utf8 -NoNewline
    }

    $unresolved = Select-String -Path (Join-Path $render '*.yaml') -Pattern 'UNSET'
    if ($unresolved) {
        $unresolved | ForEach-Object { Write-Error $_.Line }
        throw 'an image tag was left unresolved'
    }

    Write-Host '==> applying'
    Invoke-Checked 'kubectl apply' { kubectl apply -f $render }
}
finally {
    Remove-Item $render -Recurse -Force -ErrorAction SilentlyContinue
}

# ── Roll ───────────────────────────────────────────────────────────────────
Write-Host '==> waiting for rollout'
if ($buildBackend)  { Invoke-Checked 'backend rollout'  { kubectl rollout status deployment/backend  --timeout=300s } }
if ($buildFrontend) { Invoke-Checked 'frontend rollout' { kubectl rollout status deployment/frontend --timeout=300s } }
Invoke-Checked 'postgres rollout' { kubectl rollout status deployment/postgres --timeout=300s }

Write-Host ''
kubectl get pods
Write-Host ''
Write-Host '==> running images'
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}'
