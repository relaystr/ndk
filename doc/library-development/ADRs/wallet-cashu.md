# Architecture Decision Record: Wallet Cashu API

Title: Wallet Cashu - api design

## status

In progress

Updated on 04-08-2025

## contributors

- Main contributor(s): leo-lox

- Reviewer(s): frnandu, nogringo

- Final decision made by: frnandu, leo-lox, nogringo

## Context and Problem Statement

We want to introduce a wallet use-case. To support multiple types of wallets like NWC and Cashu, we need different implementations.
Depending on the specific needs of a wallet, the capabilities are different.
How can we achieve a wallet design for the Cashu wallet that works for our users as well as for the generic wallet use-case?

## Main Proposal

Give the users methods to start a action like [spend, mint, melt] and notify about pending transactions via BehaviorSubjects.
The objects, by the behavior subjects then have methods to confirm or cancel where appropriate.
This is needed so the end-user can check the fees (transaction summary) before making a transaction.

A pseudocode flow would look like this:

```dart
main(){
  BehaviorSubject<Transaction> pendingTransactions = BehaviorSubject<Transaction>();


  /// initiate a transaction
  void spend(Unit 'sat', Reciever receiver) {
    /// ...wallet implementation
  }

  /// user code listen to pending transactions
  pendingTransactions.listen((transaction) {

    /// tbd if we have a stauts pending or a diffrent subscription for done (sucessfull, err) transactions
    if (transaction.type == TransactionType.spend && transaction.status == TransactionStatus.pending) {

        /// display transaction summary to user
        displayTransactionSummary(transaction.details);

        // User confirms the transaction
        if (userConfirms()) {
         transaction.confirm()
        } else {
        transaction.cancel()
        }
    }

    if(transaction.status == TransactionStatus.done) {
        /// display result to user [sucess, error]
        displayTransactionResult(transaction);
    }

  });
}
```

Flow:

1. Listen to pending transaction
2. Initiate the transaction by calling a function.
3. React to pending transactions and confirm/decline them
4. React to transaction completed

## Consequences

The reactive nature of transactions makes it necessary to use some form of subscriptions.
Using this approach, the available options to the user/dev are quite clear.

- Pros

  - Clear separations of what options are available at a given time.
  - Data is directly available; no need to call a getter
  - Setup for the user/dev is structured
  - Clear separation between pending and final.
  - Does not necessarily require cashu/implementation knowledge

- Cons
  - Requires subscription management for the user/dev
  - More complex to implement (for us)
  - less control for the user/dev, although we can expose methods if more control is needed.

## Alternative proposals

Use functions for each transaction step and user/dev uses them manualy.
pro: - a lot more control
con: - more complex, requires cashu knolege

## Final Notes

Proposal discussed
Required more detail and experiments to proceed.
