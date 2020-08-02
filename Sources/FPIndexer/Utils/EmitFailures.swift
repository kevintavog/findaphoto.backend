
func emitFailures() {
    let failures = IndexingFailures.all()

    if failures.count > 0 {
        print("\(failures.count) FAILURES:")
        for f in failures {
            print("  \(f)")
        }
    }
}
