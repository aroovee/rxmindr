//
//  SwiftUIView.swift
//  Rxmindr
//
//  Created by Aroovee Nandakumar on 8/14/25.
//

import SwiftUI

var monday = Circle()
var tuesday = Circle()
var wednesday = Circle()
var thursday = Circle()
var friday = Circle()
var saturday = Circle()
var sunday = Circle()
var filledIn = false
var fillColor: Color?



    

struct SwiftUIView: View {
   
    var body: some View {
        HStack{
            monday
                .stroke(style:StrokeStyle(lineWidth: 5, lineCap: .round, dash: filledIn ? []: [0,10]))
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [0,10]))
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [0,10]))
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [0,10]))
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [0,10]))
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [0,10]))
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [0,10]))
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [0,10]))
        }
    }
}

#Preview {
    SwiftUIView()
}


// Need to track week in prescription object, place this in prescriptionView so that it works for each prescritpion
// Also we should try to add streak view somewhere, need to make UI more appealing and user friendly.
