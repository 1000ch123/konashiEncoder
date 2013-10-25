//
//  ismViewController.h
//  konashiLed
//
//  Created by kanade on 13/06/14.
//  Copyright (c) 2013年 kanade. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VVOSC.h"

#define OP_MODE_NUM
enum OP_MODE{
	OP_MODE_MOVE,
	OP_MODE_ROTATION
};

@interface ismViewController : UIViewController

@property int readCount;
@property int readDelay;

//osc
@property NSString* host;
@property NSString* port;

//digital
@property int preState;
@property int rotation;
@property int rotationCnt;
@property int rotationDirCnt;

//turtle_flag
@property enum OP_MODE opMode;

//gui
@property (strong,nonatomic) UILabel* label_state_title;
@property (strong,nonatomic) UILabel* label_state;
@property (strong,nonatomic) UILabel* label_value_title;
@property (strong,nonatomic) UILabel* label_value;
@property (strong,nonatomic) UILabel* label_host;
@property (strong,nonatomic) UILabel* label_port;
@property (strong,nonatomic) UITextField* text_host;
@property (strong,nonatomic) UITextField* text_port;

@property (strong,nonatomic)OSCManager* oscMan;
@property (strong,nonatomic)OSCOutPort* outPort;



@end
