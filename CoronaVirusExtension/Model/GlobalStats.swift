//
//  GlobalStats.swift
//  SafariExtension
//
//  Created by Thomas Woodfin on 3/22/20.
//  Copyright © 2020 diatoming.com. All rights reserved.
//

import Cocoa

struct GlobalStatsResponse: Codable {

    public var results : [GlobalStats]?
    public var stat : String?
}

struct GlobalStats: Codable {

    public var total_cases : Int?
    public var total_recovered : Int?
    public var total_unresolved : Int?
    public var total_deaths : Int?
    public var total_new_cases_today : Int?
    public var total_new_deaths_today : Int?
    public var total_active_cases : Int?
    public var total_serious_cases : Int?

}
