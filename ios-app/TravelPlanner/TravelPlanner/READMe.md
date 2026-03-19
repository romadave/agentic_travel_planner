Why SwiftUI uses struct for views?
- to use data driven programming model
- more performative
- when you pass in new / assign a view it creates an independent copy
- reduces / prevents side effects from shared, mutable state making the UI behaviro much easier to reason about and debug
