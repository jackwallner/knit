import Foundation
import SwiftData

/// The store's versions, oldest first.
///
/// `SchemaV1` is the data model exactly as the first public builds wrote it: a frozen copy, never edited.
/// The live models (`Project`, `Yarn`, `Needle` in Models.swift) are `SchemaV2`. A custom migration later
/// needs the shape on disk to be described, and a store is matched to a version by its model hash, so the
/// old shape has to exist as code before the models move on.
///
/// To add `SchemaV3`: move the live classes into an `enum SchemaV2`, copy them back out as the new live
/// models, add the version to `schemas` and a stage to `stages`.
enum RavelSchema {
    /// The version the app opens its store with.
    static var current: Schema { Schema(versionedSchema: SchemaV2.self) }
}

enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    static var models: [any PersistentModel.Type] { [Project.self, Yarn.self, Needle.self] }

    @Model
    final class Project {
        var name: String
        var rows: Int
        var createdAt: Date
        var finishedAt: Date?
        var yarn: String
        var needles: String
        var notes: String
        var patternFile: String?
        var patternPage: Int
        var colorRaw: String = "madder"
        var repeatLength: Int = 0
        var repeatStart: Int = 0
        var markPage: Int = -1
        var markY: Double = 0
        var markHeight: Double = 0
        var designRaw: String?
        var planData: Data?

        init(name: String, rows: Int = 0, createdAt: Date = .now) {
            self.name = name
            self.rows = rows
            self.createdAt = createdAt
            self.yarn = ""
            self.needles = ""
            self.notes = ""
            self.patternPage = 0
        }
    }

    @Model
    final class Yarn {
        var name: String
        var brand: String
        var colorway: String
        var weightRaw: String
        var skeins: Int
        var createdAt: Date

        init(name: String, brand: String = "", colorway: String = "", weightRaw: String = "worsted", skeins: Int = 1, createdAt: Date = .now) {
            self.name = name
            self.brand = brand
            self.colorway = colorway
            self.weightRaw = weightRaw
            self.skeins = skeins
            self.createdAt = createdAt
        }
    }

    @Model
    final class Needle {
        var kindRaw: String
        var millimeters: Double
        var lengthInches: Int
        var createdAt: Date

        init(kindRaw: String = "circular", millimeters: Double = 4.5, lengthInches: Int = 0, createdAt: Date = .now) {
            self.kindRaw = kindRaw
            self.millimeters = millimeters
            self.lengthInches = lengthInches
            self.createdAt = createdAt
        }
    }
}

/// The live models. Everything V2 adds is optional or carries a default, so V1 to V2 is lightweight:
/// yarn gains yardage, fiber, dye lot and its projects; a project gains a stash yarn and a second counter.
enum SchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }
    static var models: [any PersistentModel.Type] { [Project.self, Yarn.self, Needle.self] }
}

enum RavelMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self, SchemaV2.self] }
    static var stages: [MigrationStage] { [.lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)] }
}
