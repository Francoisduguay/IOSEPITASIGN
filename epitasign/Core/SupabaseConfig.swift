//
//  SupabaseConfig.swift
//  epitasign
//

import Foundation

enum SupabaseConfig {
    static var projectURL: URL? {
        guard
            let rawValue = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let url = URL(string: rawValue),
            !rawValue.contains("REMPLACE")
        else {
            return nil
        }

        return url
    }

    static var anonKey: String? {
        guard
            let rawValue = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
            !rawValue.isEmpty,
            !rawValue.contains("REMPLACE")
        else {
            return nil
        }

        return rawValue
    }
}
