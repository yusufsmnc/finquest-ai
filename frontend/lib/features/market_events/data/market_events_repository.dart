import '../domain/market_event.dart';

class MarketEventsRepository {
  static List<MarketEvent> get all {
    final now = DateTime.now();
    return [
      MarketEvent(
        id: 'evt_stock_crash',
        title: 'Stock Market Crash',
        headline: 'S&P 500 drops 12% in 3 days amid panic selling',
        description:
            'Global markets are in freefall after unexpectedly weak jobs data '
            'triggered massive institutional sell-offs. Analysts warn of a '
            'potential bear market if the index breaks key support levels. '
            'Retail investors face a critical decision: hold, sell, or buy the dip.',
        category: 'Investing',
        impact: MarketImpact.high,
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      MarketEvent(
        id: 'evt_fed_rate',
        title: 'Fed Rate Hike',
        headline: 'Federal Reserve raises rates by 0.75% — markets react',
        description:
            'The Federal Reserve announced a 75-basis-point rate increase, '
            'the largest single hike in 28 years, citing persistent inflation. '
            'Higher rates mean increased borrowing costs for mortgages, credit '
            'cards, and business loans. This decision ripples across every '
            'aspect of personal finance.',
        category: 'Investing',
        impact: MarketImpact.medium,
        timestamp: now.subtract(const Duration(hours: 8)),
      ),
      MarketEvent(
        id: 'evt_crypto_rally',
        title: 'Crypto Rally',
        headline: 'Bitcoin surges 40% this week — institutional buying confirmed',
        description:
            'Major cryptocurrency assets have spiked sharply after three '
            'institutional investment funds disclosed large Bitcoin positions. '
            'While momentum is strong, volatility remains extreme. '
            'Financial advisors caution retail investors about concentration risk '
            'and the importance of position sizing.',
        category: 'Investing',
        impact: MarketImpact.medium,
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      MarketEvent(
        id: 'evt_inflation_surge',
        title: 'Inflation Surge',
        headline: 'CPI hits 8.5% — highest reading in 40 years',
        description:
            'Consumer price inflation has reached levels not seen since the '
            '1980s, eroding purchasing power across all income brackets. '
            'Groceries, rent, and energy costs are all up significantly. '
            'Without a plan, inflation silently shrinks your savings over time. '
            'Understanding how to protect your budget is now essential.',
        category: 'Budgeting',
        impact: MarketImpact.high,
        timestamp: now.subtract(const Duration(hours: 5)),
      ),
      MarketEvent(
        id: 'evt_energy_crisis',
        title: 'Energy Bill Crisis',
        headline: 'Utility costs surge 35% — households feel the squeeze',
        description:
            'A combination of supply chain disruptions and geopolitical tensions '
            'has pushed electricity and gas prices to record highs. '
            'The average household is now spending \$400 more per year on utilities. '
            'Budgeting experts recommend an immediate audit of energy consumption '
            'and a review of monthly expense categories.',
        category: 'Budgeting',
        impact: MarketImpact.medium,
        timestamp: now.subtract(const Duration(days: 2)),
      ),
      MarketEvent(
        id: 'evt_grocery_spike',
        title: 'Grocery Price Spike',
        headline: 'Food inflation reaches 10% year-over-year',
        description:
            'Grocery bills have quietly become one of the fastest-rising '
            'household costs. Staples like eggs, bread, and produce have seen '
            'double-digit price increases. Smart budgeters are adapting with '
            'meal planning, bulk buying, and brand switching strategies. '
            'Now is the time to revisit your food budget allocation.',
        category: 'Budgeting',
        impact: MarketImpact.low,
        timestamp: now.subtract(const Duration(days: 3)),
      ),
      MarketEvent(
        id: 'evt_savings_rate_cut',
        title: 'Savings Rate Cut',
        headline: 'Banks slash savings rates from 5.0% to 2.5% overnight',
        description:
            'Following the central bank\'s shift to an accommodative policy, '
            'commercial banks have rapidly reduced rates on high-yield savings '
            'accounts and money market funds. Savers who were relying on '
            'interest income will need to reassess their short-term cash '
            'strategy and explore alternative vehicles.',
        category: 'Savings',
        impact: MarketImpact.medium,
        timestamp: now.subtract(const Duration(hours: 12)),
      ),
      MarketEvent(
        id: 'evt_unemployment_spike',
        title: 'Emergency Fund Alert',
        headline: 'Unemployment spikes to 6.2% — layoffs hit tech sector hard',
        description:
            'A wave of tech layoffs has pushed unemployment to its highest '
            'level in four years. Financial planners are urging workers across '
            'all industries to stress-test their emergency funds. '
            'The rule of thumb is 3–6 months of expenses, but economic '
            'uncertainty may warrant building a larger buffer.',
        category: 'Savings',
        impact: MarketImpact.medium,
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      MarketEvent(
        id: 'evt_cd_opportunity',
        title: 'CD Rate Opportunity',
        headline: '12-month CD rates peak at 5.8% — limited window',
        description:
            'As the rate hike cycle nears its peak, Certificate of Deposit '
            'rates have reached multi-decade highs. This creates a narrow '
            'opportunity for savers to lock in high yields before rates reverse. '
            'Understanding the trade-offs between liquidity and yield is '
            'critical to making the right decision for your cash reserves.',
        category: 'Savings',
        impact: MarketImpact.low,
        timestamp: now.subtract(const Duration(days: 4)),
      ),
      MarketEvent(
        id: 'evt_recession_warning',
        title: 'Recession Warning',
        headline: 'Yield curve inverts for 3rd consecutive month',
        description:
            'The 2-year/10-year Treasury yield curve has inverted for the '
            'third month in a row — a signal that has preceded every US '
            'recession in the past 50 years. While not a certainty, this '
            'indicator prompts a critical review of portfolio risk exposure, '
            'debt levels, and financial resilience planning.',
        category: 'Risk Management',
        impact: MarketImpact.high,
        timestamp: now.subtract(const Duration(hours: 6)),
      ),
      MarketEvent(
        id: 'evt_currency_devaluation',
        title: 'Currency Devaluation',
        headline: 'Dollar weakens 8% against major currencies this quarter',
        description:
            'The US dollar has declined significantly against the Euro, Yen, '
            'and other major currencies following signals of monetary easing. '
            'A weaker dollar raises the cost of imports, increases travel '
            'expenses, and affects internationally diversified portfolios. '
            'Understanding currency risk is now part of everyday financial planning.',
        category: 'Risk Management',
        impact: MarketImpact.medium,
        timestamp: now.subtract(const Duration(days: 2)),
      ),
      MarketEvent(
        id: 'evt_tech_bubble',
        title: 'Tech Bubble Warning',
        headline: 'NASDAQ valuations hit dot-com era levels — analysts alarmed',
        description:
            'Several major technology companies are trading at price-to-earnings '
            'ratios exceeding 100x, reminiscent of the 1999–2000 bubble. '
            'While momentum investing has rewarded risk-takers recently, '
            'concentration in a single sector dramatically amplifies downside '
            'risk. Diversification and position sizing become critical decisions.',
        category: 'Risk Management',
        impact: MarketImpact.high,
        timestamp: now.subtract(const Duration(days: 3)),
      ),
    ];
  }
}