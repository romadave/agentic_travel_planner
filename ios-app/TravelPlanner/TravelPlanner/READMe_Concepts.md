AI Travel Planner : 
We will start with an LLM-assisted parser, a deterministic evaluator, and validation of parser output.

The user enters a free-text prompt. TripPromptParser sends that prompt and parsing instructions to the LLM, which returns a ParsedPromptResult containing the travel details it could infer from the user’s input.

We then validate and normalize that parsed result, and map it into our app’s TripRequestDraft, which is the editable source of truth throughout the intake flow.

Next, TripRequestEvaluator inspects the draft and returns a TripEvaluation, which tells us what required information is still missing and whether the draft is ready for submission.

That TripEvaluation is then passed to QuestionMapper. For V0, QuestionMapper will generate static questions. Later, we can swap that layer with an LLM-based phrasing system to make the questions feel more personalized and context-aware without changing the evaluator logic.

Screen 2 begins with the first required question. As the user answers questions across screens, we keep updating the same TripRequestDraft.

Once the draft is complete, we create a final TripRequest and send it to the planning LLM when the user taps Create Plan. The LLM returns itinerary options. After the user approves a plan, we can support actions like emailing the itinerary or generating an Excel sheet.


Why SwiftUI uses struct for views?
- to use data driven programming model
- more performative
- when you pass in new / assign a view it creates an independent copy
- reduces / prevents side effects from shared, mutable state making the UI behaviro much easier to reason about and debug

#Codable
#Equatable
#Sendable
#Published - basically if the value of a property changes -> it automatically sends updates to its subscribers. 
#guard - A guard statement is used to assert that a condition must be true for execution to continue. If the condition is false, the else block must exit the current scope (using return, throw, break, or continue). This pattern is often called “early exit.”
#@State
#@StateObject
#@escaping
#@ViewBuilder
#onChange(of:) - A SwiftUI view modifier that acts as a value change listener. It watches a specific value and runs a closure whenever that value changes. Similar to an event listener or value notifier. Signature: `.onChange(of: someValue) { oldValue, newValue in ... }`. Useful when you need to react to state changes but can't (or shouldn't) put that logic directly in a property setter. Unlike `.onAppear` (runs once when view appears) or `.onDisappear` (runs when view leaves), `onChange` fires every time the watched value changes, regardless of view lifecycle.

## Streaming & SSE (Server-Sent Events)

#AsyncThrowingStream - Swift's way of creating an async sequence that produces values over time (and can throw errors). Think of it like a pipe: one side pushes values in, the other side reads them out with `for try await`. Created with `AsyncThrowingStream<Element, Error> { continuation in ... }`.

#continuation - The "push" side of an AsyncThrowingStream. It has three key methods:
  - `continuation.yield(value)` — pushes one value into the stream. The caller reading with `for try await` receives it. Like Python's `yield` in a generator.
  - `continuation.finish()` — signals the stream is done. The `for try await` loop on the other end exits normally.
  - `continuation.finish(throwing: error)` — signals the stream failed. The `for try await` loop throws the error.
  Example flow: backend sends 4 SSE events → each one gets `continuation.yield(event)` → after the last one, `continuation.finish()`.

#URLSession.shared.bytes(for:) - An async method that opens an HTTP connection and returns `(AsyncBytes, URLResponse)`. Unlike `.data(for:)` which waits for the ENTIRE response to download before returning, `.bytes(for:)` returns immediately and gives you a lazy async stream of bytes. You iterate over them as they arrive. This is essential for SSE/streaming because the server sends data over time, not all at once.
  - `.bytes(for:)` returns `AsyncBytes` — iterate byte by byte
  - `.bytes(for:).lines` — a convenience that splits the byte stream into `String` lines as they arrive
  - Example: `for try await line in bytes.lines { // process each SSE line }`

#Accept: text/event-stream - An HTTP header you set on the request to tell the server "I want to receive Server-Sent Events (SSE)". Set with: `request.setValue("text/event-stream", forHTTPHeaderField: "Accept")`. The server then sends the response as a stream of lines in the format `data: {json}\n\n`. Each `data: ` line is one event, and blank lines separate events.

## String vs Substring in Swift

#String vs Substring - In Swift, `String` and `Substring` are different types, even though they hold text.
  - `String` — owns its character data. An independent, full copy.
  - `Substring` — a "view" into an existing String's memory. Created by operations like `dropFirst()`, `prefix()`, `split()`. It doesn't copy the characters — it just points to a range within the original String.
  - Why they're separate: performance. When you do `line.dropFirst(6)`, Swift doesn't copy the entire string minus 6 characters. It just says "start reading from position 6." This is fast and memory-efficient.
  - The catch: you can't mix them freely. `let x: String = line.dropFirst(6)` won't compile. You need `String(line.dropFirst(6))` to explicitly convert.
  - Rule of thumb: use Substring for temporary/intermediate work, convert to String with `String(...)` when you need to store or pass it around.

#.data(using: .utf8) - Converts a `String` into `Data` (raw bytes). `Data` is what `JSONDecoder` needs to decode JSON. UTF-8 is the encoding standard — it defines how characters map to bytes. Almost all JSON and web content uses UTF-8.
  Example: `let data = jsonString.data(using: .utf8)` → turns `"{\"type\":\"flights\"}"` into raw bytes that JSONDecoder can parse. Returns `nil` if the string can't be encoded (rare with UTF-8), so you typically `guard let` it.

## Flutter → SwiftUI Concept Map

| Flutter | SwiftUI | Notes |
|---|---|---|
| `StatefulWidget` + `State` | `View` + `@State` | SwiftUI views are structs not classes. No separate State class needed. |
| `setState(() {...})` | Just mutate the `@State` var | SwiftUI detects changes automatically, no explicit setState call. |
| `ValueNotifier<T>` | `@State var` + `Binding<T>` | Parent owns state with @State, child gets a Binding. Like passing a ValueNotifier down to a child widget. |
| `ChangeNotifier` | `ObservableObject` + `@Published` | ViewModel pattern. @Published = notifyListeners() but automatic. |
| `Provider` / `Riverpod` | `@EnvironmentObject` | Inject shared state anywhere down the tree without passing through every widget. |
| `ValueListenableBuilder` | Not needed | SwiftUI rebuilds views automatically when @State/Binding changes. No builder widget required. |
| `Navigator.push()` | `NavigationStack` + `.navigationDestination` | Declarative — driven by state (bool/value) not imperative push/pop calls. |
| `Widget build()` | `var body: some View` | Same concept — returns the UI tree. Called whenever state changes. |
| `const MyWidget()` | Automatic | Struct views are value types, SwiftUI handles diffing. No const optimization needed. |
| `async/await` | `async/await` | Almost identical syntax. |
| `Stream<T>` | `AsyncThrowingStream<T, Error>` | Async sequence of values over time. |
| `StreamBuilder` | `for try await` in a `Task` + update `@State` | Consume streams and update state, UI rebuilds automatically. |
| `final` param in widget constructor | `let` property in struct | Immutable input to a view. |
| `TextEditingController` | `@Binding var text: String` | Two-way text field connection. Parent owns the string. |

### Binding deep dive (Flutter parallel)
In Flutter, if a parent has a `ValueNotifier<int>` and passes it to a child, the child can read `.value` and write `.value = 5`, and the parent sees the change.

In SwiftUI, it's the same pattern:
- Parent: `@State private var count: Int = 0`
- Parent passes to child: `ChildView(count: $count)` — the `$` prefix creates a `Binding`
- Child declares: `var count: Binding<Int>` (or `@Binding var count: Int`)
- Child reads: `count.wrappedValue` (or just `count` with @Binding)
- Child writes: `count.wrappedValue = 5` → parent's @State updates → both views rebuild

`Binding<Int>?` (optional) means the parent CAN pass a binding OR leave it nil. This lets a component work in two modes: externally controlled (binding provided) or self-managed (binding is nil, use internal @State).

## State Management: Shared ViewModels (Flutter ↔ SwiftUI)

### The problem
When two views need to share state (e.g. PlanningLoadingView writes stream data, ItinerariesView reads it), you can't use local `@State` — that's private to one view. Same problem in Flutter: local `setState` doesn't help when two widgets need the same data.

### Flutter solution
```dart
// 1. Create a ChangeNotifier
class TripResultNotifier extends ChangeNotifier {
  List<ItineraryOption> itineraries = [];
  List<FlightOption> flights = [];
  bool isLoadingFlights = true;

  void setFlights(List<FlightOption> f) {
    flights = f;
    isLoadingFlights = false;
    notifyListeners();  // manually tell listeners
  }
}

// 2. Provider OWNS the notifier (creates it, keeps it alive)
Provider(create: (_) => TripResultNotifier(), child: ...)

// 3. Consumer BORROWS the notifier (reads/watches it)
Consumer<TripResultNotifier>(builder: (_, notifier, __) => ...)
```

### SwiftUI equivalent
```swift
// 1. Create an ObservableObject (= ChangeNotifier)
@MainActor
class TripResultViewModel: ObservableObject {
    @Published var itineraries: [ItineraryOption] = []  // @Published = auto notifyListeners()
    @Published var flights: [FlightOption] = []
    @Published var isLoadingFlights: Bool = true
}

// 2. @StateObject OWNS it (= Provider — creates it, keeps it alive across rebuilds)
struct PlanningLoadingView: View {
    @StateObject private var resultVM = TripResultViewModel()
}

// 3. @ObservedObject BORROWS it (= Consumer — reads it, doesn't own it)
struct ItinerariesView: View {
    @ObservedObject var resultVM: TripResultViewModel
}
```

### Key mappings

| Flutter | SwiftUI | Role |
|---|---|---|
| `ChangeNotifier` | `ObservableObject` protocol | "I'm an object that notifies listeners on change" |
| `notifyListeners()` | `@Published` (automatic) | Triggers UI rebuild. In SwiftUI, just assigning to a @Published var does this — no manual call needed. |
| `Provider` (creates & owns) | `@StateObject` | **Owner** — creates the object, survives view rebuilds. Use in the PARENT that creates the view model. |
| `Consumer` / `context.watch` | `@ObservedObject` | **Borrower** — reads the object, doesn't own it. If the owner goes away, the object goes away. Use in CHILD views. |
| `context.read` (no rebuild) | Access without property wrapper | Read without subscribing to changes. |

### @StateObject vs @ObservedObject — CRITICAL difference
- `@StateObject` = **creates once, survives rebuilds**. Like `Provider` at the top of a widget tree. SwiftUI keeps the object alive even when the view struct is recreated.
- `@ObservedObject` = **borrowed reference**. Like `Consumer`. If the parent view rebuilds and creates a new instance, SwiftUI uses the new one. That's why you NEVER use `@ObservedObject var vm = SomeVM()` — it would recreate on every rebuild and lose state.
- Rule: use `@StateObject` exactly once (where you create it), `@ObservedObject` everywhere else (where you receive it).

## Array Operations

#flatMap - Does **map + flatten** in one step. When each element maps to an array, `flatMap` collects all those arrays and merges them into a single flat array.
  ```swift
  // Each HotelStop has a .hotels array:
  // HotelStop 1 → [Hotel A, Hotel B]
  // HotelStop 2 → [Hotel C]
  // HotelStop 3 → [Hotel D, Hotel E, Hotel F]

  hotelStops.map(\.hotels)     // → [[Hotel A, B], [Hotel C], [Hotel D, E, F]]  (nested)
  hotelStops.flatMap(\.hotels)  // → [Hotel A, B, C, D, E, F]                   (flat)
  ```
  - `.map` transforms each element 1:1 — array in, array of same length out.
  - `.flatMap` transforms each element into an array, then flattens all those arrays into one.
  - Flutter/Dart equivalent: `.expand()` → `hotelStops.expand((stop) => stop.hotels).toList()`
