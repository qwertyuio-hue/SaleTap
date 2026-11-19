//
//  ContentView.swift
//  SaleTap
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            StoreView()
                .tabItem { Label("商店", systemImage: "bag.fill") }

            FilesView()
                .tabItem { Label("解压", systemImage: "archivebox.fill") }
        }
        .tint(Config.accent)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
