enum BudgetRenewalPeriod {
  daily("daily"),
  weekly("weekly"),
  monthly("monthly"),
  yearly("yearly"),
  never("never");

  final String plaintext;

  const BudgetRenewalPeriod(this.plaintext);

  static BudgetRenewalPeriod fromPlaintext(String plaintext) {
    return BudgetRenewalPeriod.values.firstWhere(
      (e) => e.plaintext == plaintext,
      orElse: () => BudgetRenewalPeriod.never,
    );
  }
}
