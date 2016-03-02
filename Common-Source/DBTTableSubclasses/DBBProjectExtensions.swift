//
//  DBBProjectExtensions.swift
//  DBBuilder-Swift
//
//  Created by Dennis Birch on 3/1/16.
//  Copyright © 2016 Dennis Birch. All rights reserved.
//

import Foundation

extension DBBProject {
	
	func meetingDisplayString() -> String {
		var meetingPurposes = [String]()
		
		if meetings?.count == nil {
			return ""
		}
		
		for mtg in meetings as! [DBBMeeting] {
			if let purpose = mtg.purpose {
				meetingPurposes.append(purpose)
			}
		}
		
		return meetingPurposes.joinWithSeparator(", ")
	}
}
