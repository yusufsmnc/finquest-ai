import '../domain/mentor_message.dart';

class MentorRepository {
  static const Map<MentorContext, List<String>> _messages = {
    MentorContext.decisionCorrect: [
      'Smart move. Diversification in uncertain markets is exactly what long-term investors do.',
      'Correct. You weighed risk against reward well — that instinct will serve you over time.',
      'Well done. You identified the safer option without sacrificing potential returns.',
      'Exactly right. Staying disciplined during volatility is harder than it sounds. You did it.',
      'Perfect call. Patience and strategy always beat reactive decisions in finance.',
      "That's the kind of decision that compounds over years. Keep building this habit.",
      "Right on. You're starting to think the way experienced investors do.",
      'Spot on. Managing emotions under uncertainty is the hardest part — you nailed it.',
    ],
    MentorContext.decisionWrong: [
      "Not this time, but every wrong decision teaches more than three correct ones. Let's look at why.",
      "The market humbles everyone. What matters is understanding the reasoning behind the better path.",
      "That's a common approach, but the numbers tell a different story here. Let me explain.",
      'This happens to the best investors. The key is reviewing the decision with a calm mind.',
      "You focused on the upside — that's natural. But risk management often matters more.",
      "Don't worry. Even professional traders make this call wrong sometimes. The lesson is worth it.",
      'Close, but context changes everything in finance. Understanding why is the real reward.',
      "That instinct is understandable. Let's break down what the smarter move was and why.",
    ],
    MentorContext.levelUp: [
      'Your financial vocabulary is growing with every scenario. Keep building.',
      "You've leveled up — and so has your understanding. The patterns are becoming clearer.",
      'Milestone reached. You are developing a genuine financial instinct. That is rare.',
      'Consistency like yours is what separates learners from practitioners.',
      'Another level earned. Real-world financial thinking takes exactly this kind of practice.',
    ],
    MentorContext.streakMilestone: [
      'Three in a row. Consistency is the foundation of every successful financial strategy.',
      "You're on a streak. When decisions feel this natural, confidence follows.",
      "That's the momentum investors talk about. Keep trusting your analysis.",
      'Your decision speed and accuracy are improving together. Keep it going.',
      'Back-to-back correct calls. You are building the habit of thoughtful financial decisions.',
    ],
    MentorContext.achievementUnlock: [
      'This badge represents a real skill, not just a number.',
      'You earned this. Financial literacy is built one decision at a time.',
      'Every achievement you unlock marks a moment you chose to think differently.',
      'The habits you are building here transfer directly to real-world financial confidence.',
      "That achievement is yours. Progress like this doesn't happen by accident.",
    ],
    MentorContext.categoryBudgeting: [
      "Budgeting isn't about limiting yourself — it's about knowing exactly where your power goes.",
      "The best budgets aren't restrictive. They're simply a map of your financial priorities.",
      'Small leaks sink big ships. Tracking expenses reveals more than any income boost can.',
      'A budget gives every dollar a job. Idle money is money you are not in control of.',
    ],
    MentorContext.categoryInvesting: [
      'Investing is patience made profitable. Time in the market beats timing the market.',
      'The best investment decisions are boring ones made consistently over long periods.',
      'Market noise is constant. Your signal is the long-term trend behind it.',
      "Volatility isn't risk — it's opportunity for those with the patience to hold on.",
    ],
    MentorContext.categorySavings: [
      'Your emergency fund is your first investment. It buys you freedom to take risks elsewhere.',
      "Saving isn't about denying yourself — it's about buying your future self more options.",
      'Automating your savings removes willpower from the equation. Systems beat intentions.',
      'Every dollar saved is a vote for your future financial independence.',
    ],
    MentorContext.categoryRisk: [
      "Risk can't be eliminated — only understood, measured, and managed.",
      "The goal isn't to avoid risk. It's to take only the risks worth the potential reward.",
      'High returns always come with high risk. The skill is knowing when that trade-off makes sense.',
      "Diversification doesn't maximize returns — it maximizes your ability to stay in the game.",
    ],
    MentorContext.nextStep: [
      'Try a different scenario category next. Each one builds a different financial muscle.',
      'You are ready for a harder risk level. Challenge yourself with High Risk scenarios.',
      'Visit your achievements — seeing your progress keeps motivation high.',
      'Check your learning progress in your profile. You might be closer to mastery than you think.',
      'Three correct decisions in a row and you will feel the momentum shift.',
    ],
    MentorContext.idle: [
      'Every financial decision you make — large or small — reflects a belief about the future.',
      'The gap between where you are and where you want to be is filled with decisions like these.',
      'Financial confidence comes from knowing how to think under uncertainty.',
      'The best financial education is the kind you can apply immediately. That is what you are building here.',
      'Clarity about your financial goals makes every decision easier to evaluate.',
    ],
    MentorContext.onboarding: [
      "Welcome. I am your AI Mentor — I'll be here to explain the reasoning behind every decision.",
      "Think of me as your financial thinking partner. I don't judge calls — I help you understand them.",
      "You'll make great calls and wrong ones. Both teach something. I'll guide you through both.",
    ],
    MentorContext.newUser: [
      'Pick any scenario below — there is no wrong place to start your financial journey.',
      'Your first decision is the hardest. After that, momentum takes over.',
      'Start with whatever category interests you most. Curiosity is the best teacher.',
    ],
    MentorContext.firstWin: [
      'First scenario complete. The first step is always the most important one.',
      "One decision down. You've started building something real — keep going.",
      'You made your first financial call. That instinct will sharpen with every scenario.',
    ],
    MentorContext.streakHigh: [
      'You are building real momentum. Each correct call sharpens your financial instinct.',
      'Back-to-back decisions are how great financial habits form. You are in the zone.',
      'Consistency is the edge most investors lack. You are building it right now.',
    ],
    MentorContext.highAccuracy: [
      'Your accuracy is strong. You are reading risk better than most people ever do.',
      'That precision comes from thinking, not guessing. It will serve you in the real world.',
      'Above 80% accuracy means the patterns are clicking. Keep trusting your analysis.',
    ],
  };

  static List<String> messagesFor(MentorContext context) {
    return _messages[context] ?? _messages[MentorContext.idle]!;
  }

  static String pickMessage(MentorContext context, int index) {
    final messages = messagesFor(context);
    return messages[index % messages.length];
  }
}