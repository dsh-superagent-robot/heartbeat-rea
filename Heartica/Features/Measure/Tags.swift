import SwiftUI

enum TagColor {
    static let names = ["red", "orange", "yellow", "green", "blue", "purple", "teal", "pink"]

    static func color(_ name: String) -> Color {
        switch name {
        case "red": return AppColor.brand
        case "orange": return AppColor.orange
        case "yellow": return AppColor.warning
        case "green": return AppColor.success
        case "blue": return AppColor.blue
        case "purple": return AppColor.purple
        case "teal": return AppColor.teal
        case "pink": return Color(red: 1.0, green: 0.45, blue: 0.72)
        default: return AppColor.textSecondary
        }
    }
}

struct TagPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataStore: HealthDataStore

    let selectedTagId: String?
    let onSelect: (String?) -> Void

    @State private var selection: String?
    @State private var showCreateTag = false
    @State private var editingTag: CustomTag?
    @State private var showManageTags = false

    init(selectedTagId: String?, onSelect: @escaping (String?) -> Void) {
        self.selectedTagId = selectedTagId
        self.onSelect = onSelect
        _selection = State(initialValue: selectedTagId)
    }

    private var customTags: [CustomTag] { dataStore.customTags() }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Capsule()
                        .fill(AppColor.separator)
                        .frame(width: 38, height: 4)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Select Tag")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(AppColor.textPrimary)
                        Text("Tag your measurements to better understand how your lifestyle impacts your heart rate.")
                            .font(.system(size: 13))
                            .foregroundColor(AppColor.textSecondary)
                            .lineSpacing(2)
                    }

                    noTagRow

                    ForEach(TagCategory.all) { category in
                        categorySection(category)
                    }

                    customSection

                    Button("Manage Custom Tags") {
                        showManageTags = true
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColor.brand)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }

            VStack(spacing: 8) {
                Button("Continue") {
                    onSelect(selection)
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
                if let count = selectedCountText {
                    Text(count)
                        .font(.system(size: 11))
                        .foregroundColor(AppColor.textSecondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background(AppColor.surface.ignoresSafeArea(edges: .bottom))
        }
        .screenBackground()
        .sheet(isPresented: $showCreateTag) {
            CustomTagEditorView(tag: nil)
                .environmentObject(dataStore)
        }
        .sheet(item: $editingTag) { tag in
            CustomTagEditorView(tag: tag)
                .environmentObject(dataStore)
        }
        .sheet(isPresented: $showManageTags) {
            CustomTagsManageView()
                .environmentObject(dataStore)
        }
    }

    private var selectedCountText: String? {
        guard customTags.count >= 20 else { return nil }
        return L("Tag limit reached 20/20")
    }

    private var noTagRow: some View {
        Button {
            selection = nil
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "tag.slash")
                    .font(.system(size: 14))
                Text("No Tag")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                if selection == nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColor.brand)
                }
            }
            .foregroundColor(AppColor.textPrimary)
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AppColor.surface))
        }
        .buttonStyle(.plain)
    }

    private func categorySection(_ category: TagCategory) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(category.displayTitle)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColor.textSecondary)
            FlowLayout(spacing: 8) {
                ForEach(PresetTag.all.filter { $0.categoryID == category.id }) { tag in
                    tagChip(id: tag.id, title: tag.displayTitle, colorName: tag.colorName)
                }
            }
        }
    }

    private var customSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Custom")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColor.textSecondary)
                Spacer()
                Button {
                    showCreateTag = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text(customTags.count >= 20 ? "20/20" : "New Tag")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(customTags.count >= 20 ? AppColor.textSecondary : AppColor.brand)
                }
                .disabled(customTags.count >= 20)
            }
            if customTags.isEmpty {
                Text("Create your own tags to track personal patterns.")
                    .font(.system(size: 12))
                    .foregroundColor(AppColor.textSecondary)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(customTags) { tag in
                        tagChip(id: tag.id, title: tag.name, colorName: tag.colorName)
                    }
                }
            }
        }
    }

    private func tagChip(id: String, title: String, colorName: String) -> some View {
        Button {
            selection = selection == id ? nil : id
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(TagColor.color(colorName))
                    .frame(width: 6, height: 6)
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(selection == id ? .white : AppColor.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(selection == id ? TagColor.color(colorName) : AppColor.surface)
                    .overlay(Capsule().stroke(AppColor.separator.opacity(selection == id ? 0 : 1), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }
}

struct CustomTagsManageView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataStore: HealthDataStore
    @State private var showCreate = false
    @State private var editing: CustomTag?

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(dataStore.customTags()) { tag in
                        Button {
                            editing = tag
                        } label: {
                            HStack(spacing: 10) {
                                Circle().fill(TagColor.color(tag.colorName)).frame(width: 10, height: 10)
                                Text(tag.name)
                                    .foregroundColor(AppColor.textPrimary)
                                Spacer()
                                Text(TagCluster.titled(tag.cluster)?.displayTitle ?? L("General"))
                                    .font(.system(size: 11))
                                    .foregroundColor(AppColor.textSecondary)
                            }
                        }
                    }
                    .onDelete { offsets in
                        let tags = dataStore.customTags()
                        for index in offsets { dataStore.deleteCustomTag(id: tags[index].id) }
                    }
                } header: {
                    Text(LF("%d/20 tags", dataStore.customTags().count))
                }
                Section {
                    Button {
                        showCreate = true
                    } label: {
                        Label("New Tag", systemImage: "plus.circle.fill")
                    }
                    .disabled(dataStore.customTags().count >= 20)
                }
            }
            .navigationTitle("Custom Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showCreate) {
                CustomTagEditorView(tag: nil)
                    .environmentObject(dataStore)
            }
            .sheet(item: $editing) { tag in
                CustomTagEditorView(tag: tag)
                    .environmentObject(dataStore)
            }
        }
    }
}

struct CustomTagEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataStore: HealthDataStore

    let tag: CustomTag?

    @State private var name: String
    @State private var cluster: String
    @State private var colorName: String

    init(tag: CustomTag?) {
        self.tag = tag
        _name = State(initialValue: tag?.name ?? "")
        _cluster = State(initialValue: tag?.cluster ?? "")
        _colorName = State(initialValue: tag?.colorName ?? "red")
    }

    private var isEditing: Bool { tag != nil }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && !cluster.isEmpty }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Name")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColor.textSecondary)
                        TextField("Name", text: $name)
                            .font(.system(size: 16))
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(AppColor.surfaceAlt))
                            .onChange(of: name) { newValue in
                                if newValue.count > 30 { name = String(newValue.prefix(30)) }
                            }
                        Text("\(name.count)/30")
                            .font(.system(size: 10))
                            .foregroundColor(AppColor.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Tag Cluster *")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColor.textSecondary)
                        Menu {
                            ForEach(TagCluster.all) { item in
                                Button(item.displayTitle) { cluster = item.id }
                            }
                        } label: {
                            HStack {
                                Text(TagCluster.titled(cluster)?.displayTitle ?? L("Select"))
                                    .font(.system(size: 16))
                                    .foregroundColor(cluster.isEmpty ? AppColor.textSecondary : AppColor.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppColor.textSecondary)
                            }
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(AppColor.surfaceAlt))
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Color")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColor.textSecondary)
                        HStack(spacing: 14) {
                            ForEach(TagColor.names, id: \.self) { name in
                                Button {
                                    colorName = name
                                } label: {
                                    Circle()
                                        .fill(TagColor.color(name))
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle()
                                                .stroke(AppColor.textPrimary, lineWidth: colorName == name ? 2 : 0)
                                                .padding(-4)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if isEditing {
                        Button(role: .destructive) {
                            if let tag { dataStore.deleteCustomTag(id: tag.id) }
                            dismiss()
                        } label: {
                            Text("Delete Tag")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppColor.danger)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(RoundedRectangle(cornerRadius: 14).fill(AppColor.danger.opacity(0.1)))
                        }
                    }
                }
                .padding(20)
            }
            .screenBackground()
            .navigationTitle(isEditing ? "Edit" : "New Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let tag {
                            dataStore.updateCustomTag(id: tag.id, name: name, colorName: colorName, cluster: cluster)
                        } else {
                            dataStore.createCustomTag(name: name, colorName: colorName, cluster: cluster)
                        }
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}

// MARK: - Flow layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var height: CGFloat = 0
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                height += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: width.isFinite ? width : x, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
