import SwiftUI

// MARK: - Alumni View

struct AlumniView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = AlumniViewModel()
    @State private var showAddAlumni = false

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Alumni Network")
                            .font(.ghTitle).foregroundColor(.ghText)
                        Text("\(vm.alumni.count) alumni connected")
                            .font(.ghCaption).foregroundColor(.ghTextMuted)
                    }
                    Spacer()
                    if authVM.currentUser.role.isOfficer {
                        Button { showAddAlumni = true } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22)).foregroundColor(.ghGold)
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.top, 60).padding(.bottom, 12)

                // Search + mentor filter
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14)).foregroundColor(.ghTextMuted)
                        TextField("", text: $vm.searchText)
                            .placeholder(when: vm.searchText.isEmpty) {
                                Text("Search alumni...").foregroundColor(.ghTextMuted)
                            }
                            .font(.ghBody).foregroundColor(.ghText)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .background(Color.ghSurface2)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Button {
                        vm.mentorOnly.toggle()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill.checkmark")
                                .font(.system(size: 12))
                            Text("Mentors")
                                .font(.ghCaptionBold)
                        }
                        .foregroundColor(vm.mentorOnly ? .black : .ghGold)
                        .padding(.horizontal, 12).padding(.vertical, 9)
                        .background(vm.mentorOnly ? Color.ghGold : Color.ghGold.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .animation(.easeInOut(duration: 0.15), value: vm.mentorOnly)
                }
                .padding(.horizontal, 16).padding(.bottom, 8)

                Divider().background(Color.ghBorder)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(vm.filtered) { alumni in
                            NavigationLink(destination: AlumniDetailView(alumni: alumni)) {
                                AlumniRow(alumni: alumni)
                            }
                            .buttonStyle(.plain)
                            Divider().background(Color.ghBorder).padding(.leading, 68)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear { vm.load(chapter: authVM.currentUser.chapter) }
        .sheet(isPresented: $showAddAlumni) {
            AddAlumniView(chapter: authVM.currentUser.chapter)
        }
    }
}

// MARK: - Alumni Row

struct AlumniRow: View {
    let alumni: AlumniMember

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(initials: alumni.initials, colorHex: alumni.avatarColor, size: 48)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(alumni.name).font(.ghHeadline).foregroundColor(.ghText)
                    if alumni.canMentor {
                        Image(systemName: "person.fill.checkmark")
                            .font(.system(size: 10)).foregroundColor(.ghGreen)
                    }
                }
                Text(alumni.currentRole)
                    .font(.ghCaption).foregroundColor(.ghTextMuted).lineLimit(1)
                Text(alumni.company)
                    .font(.ghCaption).foregroundColor(.ghGold).lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("'\(String(alumni.graduationYear).suffix(2))")
                    .font(.ghCaptionBold).foregroundColor(.ghTextMuted)
                Text(alumni.city.components(separatedBy: ",").first ?? alumni.city)
                    .font(.ghCaption).foregroundColor(.ghTextMuted).lineLimit(1)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11)).foregroundColor(.ghTextMuted)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
}

// MARK: - Alumni Detail

struct AlumniDetailView: View {
    let alumni: AlumniMember

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Hero
                    VStack(spacing: 14) {
                        AvatarView(initials: alumni.initials,
                                   colorHex: alumni.avatarColor, size: 80)
                        VStack(spacing: 4) {
                            Text(alumni.name).font(.ghTitle).foregroundColor(.ghText)
                            Text(alumni.currentRole).font(.ghCallout).foregroundColor(.ghTextMuted)
                            Text(alumni.company).font(.ghCallout).foregroundColor(.ghGold)
                        }

                        if alumni.canMentor {
                            HStack(spacing: 5) {
                                Image(systemName: "person.fill.checkmark")
                                    .font(.system(size: 12)).foregroundColor(.ghGreen)
                                Text("Available to mentor")
                                    .font(.ghCaptionBold).foregroundColor(.ghGreen)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 5)
                            .background(Color.ghGreen.opacity(0.1)).clipShape(Capsule())
                        }

                        if !alumni.bio.isEmpty {
                            Text(alumni.bio).font(.ghCallout).foregroundColor(.ghTextMuted)
                                .multilineTextAlignment(.center).padding(.horizontal, 20)
                        }

                        if !alumni.interests.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(alumni.interests, id: \.self) { i in
                                        Text(i).ghPill(color: .ghBlue)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 8)

                    // Info card
                    VStack(spacing: 0) {
                        AlumniInfoRow(icon: "graduationcap.fill", label: "Major",
                                      value: alumni.major)
                        Divider().background(Color.ghBorder)
                        AlumniInfoRow(icon: "calendar.circle.fill", label: "Graduated",
                                      value: "Class of \(alumni.graduationYear)")
                        Divider().background(Color.ghBorder)
                        AlumniInfoRow(icon: "person.badge.clock.fill", label: "Pledge Class",
                                      value: alumni.pledgeClass)
                        Divider().background(Color.ghBorder)
                        AlumniInfoRow(icon: "mappin.circle.fill", label: "Location",
                                      value: alumni.city)
                    }
                    .ghCard()

                    // Contact buttons
                    HStack(spacing: 12) {
                        Link(destination: URL(string: "mailto:\(alumni.email)")!) {
                            HStack(spacing: 6) {
                                Image(systemName: "envelope.fill").font(.system(size: 14))
                                Text("Email").font(.ghHeadline)
                            }
                            .foregroundColor(.ghBlue)
                            .frame(maxWidth: .infinity).frame(height: 46)
                            .background(Color.ghBlue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.ghBlue.opacity(0.3), lineWidth: 0.5))
                        }

                        if !alumni.linkedIn.isEmpty {
                            Link(destination: URL(string: "https://\(alumni.linkedIn)")!) {
                                HStack(spacing: 6) {
                                    Image(systemName: "link").font(.system(size: 14))
                                    Text("LinkedIn").font(.ghHeadline)
                                }
                                .foregroundColor(.ghPurple)
                                .frame(maxWidth: .infinity).frame(height: 46)
                                .background(Color.ghPurple.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.ghPurple.opacity(0.3), lineWidth: 0.5))
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle(alumni.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct AlumniInfoRow: View {
    let icon: String; let label: String; let value: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 14))
                .foregroundColor(.ghGold).frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.ghCaption).foregroundColor(.ghTextMuted)
                Text(value).font(.ghCallout).foregroundColor(.ghText)
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 11)
    }
}

// MARK: - Add Alumni Sheet

struct AddAlumniView: View {
    let chapter: String
    @Environment(\.dismiss) var dismiss
    @StateObject private var db = AlumniViewModel()

    @State private var name = ""; @State private var gradYear = "2020"
    @State private var major = ""; @State private var role = ""
    @State private var company = ""; @State private var city = ""
    @State private var email = ""; @State private var linkedIn = ""
    @State private var bio = ""; @State private var canMentor = false
    @State private var pledgeClass = ""

    let colors = ["#C9A84C","#4C6BC9","#4CC99A","#C94C8A","#8A4CC9"]

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                Capsule().fill(Color.ghBorder).frame(width: 40, height: 4).padding(.top, 12)
                HStack {
                    Button("Cancel") { dismiss() }.font(.ghCallout).foregroundColor(.ghTextMuted)
                    Spacer()
                    Text("Add Alumni").font(.ghHeadline).foregroundColor(.ghText)
                    Spacer()
                    Button("Add") {
                        let initials = name.split(separator: " ")
                            .compactMap { $0.first.map(String.init) }.prefix(2)
                            .joined().uppercased()
                        let alumnus = AlumniMember(
                            id: UUID().uuidString, name: name, initials: initials,
                            avatarColor: colors.randomElement()!,
                            graduationYear: Int(gradYear) ?? 2020,
                            major: major, currentRole: role, company: company,
                            city: city, email: email, linkedIn: linkedIn, bio: bio,
                            canMentor: canMentor, interests: [], pledgeClass: pledgeClass)
                        Task { try? await FirestoreService.shared.createAlumni(alumnus, chapter: chapter) }
                        dismiss()
                    }
                    .font(.ghCallout).foregroundColor(name.isEmpty ? .ghTextMuted : .ghGold)
                    .disabled(name.isEmpty)
                }
                .padding(.horizontal, 20).padding(.vertical, 16)
                Divider().background(Color.ghBorder)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        SectionLabel("Identity")
                        GHTextField(label: "Full Name",    placeholder: "Dr. Raymond Cole", text: $name)
                        GHTextField(label: "Pledge Class", placeholder: "Fall 2004",         text: $pledgeClass)
                        HStack(spacing: 10) {
                            GHTextField(label: "Grad Year", placeholder: "2020", text: $gradYear)
                                .keyboardType(.numberPad)
                            GHTextField(label: "Major",     placeholder: "Pre-Med", text: $major)
                        }

                        SectionLabel("Professional").padding(.top, 6)
                        GHTextField(label: "Current Role", placeholder: "Cardiologist",    text: $role)
                        GHTextField(label: "Company",      placeholder: "Sentara Health",  text: $company)
                        GHTextField(label: "City",         placeholder: "Norfolk, VA",      text: $city)

                        SectionLabel("Contact").padding(.top, 6)
                        GHTextField(label: "Email",   placeholder: "name@email.com",      text: $email)
                            .keyboardType(.emailAddress).autocapitalization(.none)
                        GHTextField(label: "LinkedIn", placeholder: "linkedin.com/in/...", text: $linkedIn)
                            .autocapitalization(.none)

                        GHTextField(label: "Bio", placeholder: "A short bio...", text: $bio)

                        Toggle(isOn: $canMentor) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Available to Mentor").font(.ghCallout).foregroundColor(.ghText)
                                Text("Will appear in mentor filter for active members")
                                    .font(.ghCaption).foregroundColor(.ghTextMuted)
                            }
                        }
                        .tint(.ghGreen).padding(14).ghCard()
                    }
                    .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 40)
                }
            }
        }
    }
}
