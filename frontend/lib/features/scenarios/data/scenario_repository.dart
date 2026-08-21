import '../domain/scenario_model.dart';

class ScenarioRepository {
  ScenarioRepository._();

  static List<Scenario> all() => const [
        Scenario(
          id: 'sc-001',
          title: 'Market Crash Alert',
          description:
              'The stock market drops 18% in a single week. Your portfolio is down \$2,400. '
              'Panic headlines flood social media. Friends are selling everything. '
              'What do you do with your long-term investments?',
          category: 'Investing',
          riskLevel: RiskLevel.high,
          xpCorrect: 50,
          xpParticipation: 10,
          options: [
            ScenarioOption(
              id: 'A',
              text: 'Hold your position — this is temporary volatility.',
              isCorrect: true,
              feedbackText:
                  'Smart move. Selling during a crash locks in losses permanently.',
            ),
            ScenarioOption(
              id: 'B',
              text: 'Sell everything to stop the bleeding.',
              isCorrect: false,
              feedbackText:
                  'Panic selling is the #1 wealth destroyer in volatile markets.',
            ),
          ],
          mentorExplanation:
              'Historically, markets have recovered from every crash — including 2008, 2020, and beyond. '
              'Investors who held through the 2020 crash saw 70% gains within 12 months. '
              'Time in the market beats timing the market.',
        ),
        Scenario(
          id: 'sc-002',
          title: 'Emergency Fund Dilemma',
          description:
              'A friend tells you about a crypto coin that doubled in 3 weeks. '
              'You have a \$5,000 emergency fund sitting in savings at 4% APY. '
              'He says "this is a once-in-a-lifetime opportunity." What do you do?',
          category: 'Savings',
          riskLevel: RiskLevel.medium,
          xpCorrect: 50,
          xpParticipation: 10,
          options: [
            ScenarioOption(
              id: 'A',
              text: 'Keep the emergency fund intact.',
              isCorrect: true,
              feedbackText:
                  'Correct. Emergency funds are insurance, not investment capital.',
            ),
            ScenarioOption(
              id: 'B',
              text: 'Invest 50% — I can rebuild the fund later.',
              isCorrect: false,
              feedbackText:
                  'If an emergency hits, you\'d be forced to sell at a loss or go into debt.',
            ),
          ],
          mentorExplanation:
              'An emergency fund\'s purpose is financial stability, not growth. '
              '"Once-in-a-lifetime" opportunities appear every week in speculative markets — '
              'but a broken car or medical bill can\'t wait. Keep 3–6 months of expenses always liquid.',
        ),
        Scenario(
          id: 'sc-003',
          title: 'Credit Card Trap',
          description:
              'You carry \$2,000 on a credit card at 22% APR. '
              'You also have \$2,500 in a savings account earning 4.5% APY. '
              'Your monthly minimum payment is \$45. What\'s the smart move?',
          category: 'Budgeting',
          riskLevel: RiskLevel.high,
          xpCorrect: 50,
          xpParticipation: 10,
          options: [
            ScenarioOption(
              id: 'A',
              text: 'Pay off the full credit card balance now.',
              isCorrect: true,
              feedbackText:
                  'Paying 22% debt with 4.5% savings is a guaranteed 17.5% return.',
            ),
            ScenarioOption(
              id: 'B',
              text: 'Pay the minimum — keep savings for opportunities.',
              isCorrect: false,
              feedbackText:
                  'At minimum payments, this \$2,000 debt costs \$1,800+ in interest over 5 years.',
            ),
          ],
          mentorExplanation:
              'Eliminating high-interest debt is the highest guaranteed return available. '
              'You\'re effectively "earning" 22% by paying off the card — '
              'far better than any savings account or index fund average return.',
        ),
        Scenario(
          id: 'sc-004',
          title: 'Hot Stock Temptation',
          description:
              'A tech company has returned 85% this year. '
              'You have \$8,000 to invest. Every analyst on social media says it\'s a sure thing. '
              'Your plan was to diversify into an index fund. Do you change course?',
          category: 'Investing',
          riskLevel: RiskLevel.high,
          xpCorrect: 50,
          xpParticipation: 10,
          options: [
            ScenarioOption(
              id: 'A',
              text: 'Stick to the diversified index fund plan.',
              isCorrect: true,
              feedbackText:
                  'Diversification reduces risk. One bad quarter can erase years of gains.',
            ),
            ScenarioOption(
              id: 'B',
              text: 'Go all-in — 85% returns don\'t come around often.',
              isCorrect: false,
              feedbackText:
                  'Concentration risk: if the company stumbles, you lose everything at once.',
            ),
          ],
          mentorExplanation:
              'When "everyone" agrees something is a sure thing, it\'s usually already priced in. '
              'Index funds outperform 92% of actively managed funds over 15+ years. '
              'Boring diversification beats exciting concentration over time.',
        ),
        Scenario(
          id: 'sc-005',
          title: 'Lifestyle Upgrade Trap',
          description:
              'The new iPhone 16 Pro is out at \$1,100. Your current phone works fine. '
              'Your bank offers 0% APR financing for 12 months. '
              'You could split it into \$92/month payments. What do you do?',
          category: 'Budgeting',
          riskLevel: RiskLevel.low,
          xpCorrect: 50,
          xpParticipation: 10,
          options: [
            ScenarioOption(
              id: 'A',
              text: 'Wait, save the \$92/month, buy when you can afford it.',
              isCorrect: true,
              feedbackText:
                  'Delayed gratification builds wealth. In 12 months you\'d have the money and no debt.',
            ),
            ScenarioOption(
              id: 'B',
              text: 'Get it now — 0% APR means it\'s free money.',
              isCorrect: false,
              feedbackText:
                  '"0% APR" still means debt. Miss one payment and you\'re hit with back-interest.',
            ),
          ],
          mentorExplanation:
              'Lifestyle inflation is one of the most common wealth blockers. '
              '\$92/month invested over 10 years at 8% annual return becomes \$16,900. '
              'Your current phone keeps working. Compound growth doesn\'t pause for upgrades.',
        ),
      ];

  static List<String> categories() =>
      all().map((s) => s.category).toSet().toList();
}