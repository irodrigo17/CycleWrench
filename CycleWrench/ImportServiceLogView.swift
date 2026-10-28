import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportServiceLogView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedBikeID") private var selectedBikeID = ""
    @State private var choosingFile = false
    @State private var archive: ServiceLogArchive?
    @State private var importError: String?
    @State private var resultMessage: String?

    var body: some View {
        Form {
            Section {
                Text("Import a CycleWrench JSON service log. Dates can be omitted for older notes; the odometer preserves their order.")
                Button("Choose file", systemImage: "doc") { choosingFile = true }
            }
            if let archive {
                Section("Preview") {
                    LabeledContent("Bike", value: archive.bikeName)
                    LabeledContent("Records", value: archive.records.count.formatted())
                    LabeledContent("Source unit", value: archive.distanceUnit)
                    LabeledContent("Undated records", value: archive.records.filter { $0.date == nil }.count.formatted())
                    Button("Import into bike") { apply(archive) }
                        .disabled(resultMessage != nil)
                }
            }
            if let resultMessage {
                Section {
                    Label(resultMessage, systemImage: "checkmark.circle")
                    Button("Done") { dismiss() }
                }
            }
        }
        .navigationTitle("Import service log")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $choosingFile, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                let granted = url.startAccessingSecurityScopedResource()
                defer { if granted { url.stopAccessingSecurityScopedResource() } }
                archive = try ServiceLogArchive.decode(Data(contentsOf: url))
                resultMessage = nil
            } catch { importError = error.localizedDescription }
        }
        .alert("Couldn’t import log", isPresented: Binding(
            get: { importError != nil }, set: { if !$0 { importError = nil } }
        )) {
            Button("OK", role: .cancel) { importError = nil }
        } message: { Text(importError ?? "Please try again.") }
    }

    private func apply(_ archive: ServiceLogArchive) {
        do {
            let result = try ServiceLogImporter.importArchive(archive, into: context)
            selectedBikeID = result.bike.id.uuidString
            resultMessage = "Added \(result.addedCount) records to \(result.bike.name)."
        } catch { importError = error.localizedDescription }
    }
}
