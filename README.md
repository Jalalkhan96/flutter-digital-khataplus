# KhataPlus — a shopkeeper's notebook, digitised

KhataPlus is a Flutter digital ledger (**khata**) app for small shops.
The paper notebook a shopkeeper keeps for credit customers — who took
what, who paid what, who still owes how much — rebuilt as a phone app:
same habit, no lost pages, and the totals always add up.

> Built by **Jalal Khan** — Flutter / Dart.
> One of the projects in my portfolio: a real, working ledger with
> customers, credit & payment entries, live balances and a daily summary.

## What it does

- **Customers (khata pages)** — add a customer once with name, phone and
  an optional address/note. An **opening balance** field carries over
  whatever they already owed from the paper book.
- **Two buttons, whole business** — on a customer's page:
  - **Udhaar diya** (credit): goods or money given. Balance goes up.
  - **Paise mile** (payment): money received back. Balance goes down.
  Every entry takes an amount, an optional note ("2 kg cheeni, 1 litre
  doodh") and a date (entries forgotten in the evening rush can be
  back-dated).
- **Live balances, never typed by hand** — every balance in the app is
  calculated from the entries themselves, so a screen can never disagree
  with the ledger. Negative balance = the customer paid in advance and
  is shown as "advance".
- **Ledger with running balance** — a customer's full history, newest
  first, each row showing the balance right after that entry.
- **Home summary** — total still to receive ("kul lena"), today's
  credit and today's receipts, and how many customers currently have a
  due balance. Customers are sorted by biggest due first.
- **Search** — by customer name or phone number.
- **Fully offline, private by design** — all data is stored on the
  device (JSON in `shared_preferences`). No account, no server, no
  internet needed; the shop's book never leaves the shopkeeper's phone.
- **Delete safely** — entries delete on long-press with a confirmation;
  deleting a customer asks first and removes their ledger with them.

## How the money maths works

All calculations live in one pure-Dart file, `lib/models/ledger.dart`,
with no Flutter imports, and every screen calls those functions:

| Function | Meaning |
|---|---|
| `ledgerBalance(customerId, entries)` | Credit total − payment total for one customer |
| `totalReceivable(customerIds, entries)` | Sum of all positive balances (money the shop is still to receive) |
| `totalForDay(entries, type, day)` | One type of entry summed for one calendar day (the "today" strip) |
| `runningBalances(customerId, entries)` | Balance after each entry, newest first |
| `customerMatches(name, phone, query)` | Case-insensitive name / phone search |

Because the rules live in one place, they are unit-tested directly
(`test/ledger_test.dart`) and also verifiable without Flutter:

```bash
dart run tool/logic_check.dart   # 20 standalone checks of the ledger maths
flutter test                     # the full test suite
```

## Project structure

```
lib/
  main.dart                     App entry, theme, controller wiring
  models/
    customer.dart               Customer + JSON (de)serialisation
    khata_entry.dart            One ledger line: credit or payment
    ledger.dart                 All balance/total calculations (pure Dart)
  services/
    khata_store.dart            On-device storage (shared_preferences + JSON)
  state/
    khata_controller.dart       App state (ChangeNotifier); UI reads, methods mutate
  screens/
    home_screen.dart            Summary strip, search, customer list
    add_customer_screen.dart    New customer + opening balance
    customer_detail_screen.dart Balance header, ledger, Udhaar/Paise buttons
    add_entry_screen.dart       Amount, note and date for one entry
  utils/
    format.dart                 "Rs 1,250" formatting, amount parsing, dates
test/
  ledger_test.dart              Unit tests for the ledger maths and formatting
tool/
  logic_check.dart              Standalone Dart check (no Flutter needed)
```

## Run it

This repository contains the complete Dart source. The native Android/iOS
scaffolding is generated once by Flutter (it is standard boilerplate and
mostly binary assets, so it is not committed here):

```bash
flutter create --platforms=android,ios --org com.khataplus .
flutter pub get
flutter run
```

Requires Flutter 3.10+ / Dart 3.0+.

## Design notes

- **Balances are derived, never stored** — the classic khata bug is a
  "total" that drifts from the entries; deriving it removes the whole
  class of bug.
- **Amounts are stored positive**; the sign comes from the entry type
  (credit/payment), which keeps old entries unambiguous.
- **One dependency** (`shared_preferences`) beyond Flutter itself — the
  app stays small, fast and easy to audit.
