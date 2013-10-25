//
//  ismViewController.m
//  konashiLed
//
//  Created by kanade on 13/06/14.
//  Copyright (c) 2013年 kanade. All rights reserved.
//

#import "ismViewController.h"
#import "Konashi.h"


@interface ismViewController ()

@end

@implementation ismViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	//konahsi
	_readCount = 0;
	_readDelay = 10;
	
	_preState = 0;
	_rotation = 0;
	
	[Konashi initialize];
	
	[Konashi pinModeAll:0b00111111];
	
	[Konashi addObserver:self selector:@selector(ledOn) name:KONASHI_EVENT_READY];
	//[Konashi addObserver:self selector:@selector(readAIO1) name:KONASHI_EVENT_UPDATE_ANALOG_VALUE_AIO1];
	[Konashi addObserver:self selector:@selector(digRead) name:KONASHI_EVENT_UPDATE_PIO_INPUT];
	[Konashi addObserver:self selector:@selector(disconnect) name:KONASHI_EVENT_DISCONNECTED];
	//[Konashi findWithName:@"konashi#4-0717"];
	
	//VVOSC_ios
	//_host = @"192.168.1.91"; // tmp ipad
	//_host = @"192.168.1.32"; // tmp ipad mini
	//_host = @"192.168.1.42";
	//_host = @"192.168.11.8"; // home
	//_host = @"192.168.1.101";  // GL01P-20F3A38C8C67
	//_host = @"192.168.43.136"; //nicola
	//_host = @"192.168.11.4"; //buffalo_wmr300
	_host = @"192.168.11.18"; //sentan

	//_host = @"192.168.11.6"; // tmp_home_masanote
	//_host = @"192.168.1.69"; // tmp_keje_masanote
	//_host = @"192.168.56.1";
	_port = @"12345";
	
	_opMode = OP_MODE_MOVE;
	
	_oscMan = [[OSCManager alloc] init];
	_oscMan.delegate = self;
	
	//_outPort = [_oscMan createNewOutputToAddress:_host atPort:[_port intValue]];
	
	
	//GUI
	
	CGRect rect = CGRectMake(20, 20, 100, 30);
	
	_label_host = [[UILabel alloc] initWithFrame:rect];
	_label_host.text = @"host";
	[self.view addSubview:_label_host];
	
	rect.origin.y += 50;
	_text_host = [[UITextField alloc] initWithFrame:CGRectMake(20, 70, 280, 30)];
	_text_host.placeholder = @"input host number";
	_text_host.borderStyle = UITextBorderStyleRoundedRect;
	_text_host.clearButtonMode = UITextFieldViewModeAlways;
	[_text_host addTarget:self
				   action:@selector(text_host_update:)
		 forControlEvents:UIControlEventEditingDidEndOnExit];
	[self.view addSubview:_text_host];
	
	rect.origin.y += 50;
	_label_state_title = [[UILabel alloc] initWithFrame:rect];
	_label_state_title.text = @"通信状況";
	[self.view addSubview:_label_state_title];
	
	rect.origin.y += 50;
	_label_state = [[UILabel alloc] initWithFrame:rect];
	_label_state.text = @"none";
	[self.view addSubview:_label_state];
	
	rect.origin.y += 50;
	_label_value_title = [[UILabel alloc] initWithFrame:rect];
	_label_value_title.text = @"value";
	[self.view addSubview:_label_value_title];
	
	rect.origin.y += 50;
	_label_value = [[UILabel alloc] initWithFrame:rect];
	_label_value.text = @"none";
	[self.view addSubview:_label_value];
	
	rect.origin.y += 50;
	UIButton* btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[btn setTitle:@"connect" forState:UIControlStateNormal];
	[btn setFrame:rect];
	[btn addTarget:self
			action:@selector(buttonPushed:)
  forControlEvents:UIControlEventTouchDown];
	[self.view addSubview:btn];
	
	rect.origin.y += 50;
	btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[btn setTitle:@"stop" forState:UIControlStateNormal];
	[btn setFrame:rect];
	[btn addTarget:self
			action:@selector(stopButtonPushed:)
  forControlEvents:UIControlEventTouchDown];
	[self.view addSubview:btn];
	
	rect.origin.y += 50;
	btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[btn setTitle:@"opmode" forState:UIControlStateNormal];
	[btn setFrame:rect];
	[btn addTarget:self
			action:@selector(opButtonPushed:)
  forControlEvents:UIControlEventTouchDown];
	[self.view addSubview:btn];
	
	NSLog(@"start.");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillDisappear:(BOOL)animated
{
	[Konashi disconnect];
}

-(void)ledOn
{
	NSLog(@"ledOn!");
	[Konashi pinMode:LED2 mode:OUTPUT];
	[Konashi digitalWrite:LED2 value:HIGH];
	
	[Konashi analogReadRequest:AIO1];
	
	self.label_state.text = @"connect";
}

-(void)readAIO1
{
	int val = [Konashi analogRead:AIO1];
	NSLog(@"analog read:%d",_readCount);
	NSLog(@"value:%d",val);
	_readCount++;
	
	[Konashi analogReadRequest:AIO1];
	
	OSCMessage *message = [OSCMessage createWithAddress:@"/test"];
	[message addInt:val];
	[_outPort sendThisPacket:[OSCPacket createWithContent:message]];
	
	self.label_value.text =[NSString stringWithFormat:@"%d",val];
}

-(void)digRead
{

	int state =[self checkEncoderState];
	NSLog(@"state:%d cnt:%d",state,_rotationCnt);
	
	if(state == _preState) return;
	

	int det = state + (_preState<<1);
	NSLog(@"det:%d",det);
	
	int rotFrag = (det >> 1) & 1;
	NSLog(@"rotFrag:%d",rotFrag);

	_rotationDirCnt += rotFrag;
	
	_rotationCnt += 1;
	
	if (_rotationCnt <= 12) {_preState = state;return;}
	
	_rotationCnt = 0;
	
	OSCMessage *message;
	
	switch (_opMode) {
		case OP_MODE_MOVE:
			if (_rotationDirCnt >= 6) {
				_rotation -= 25;
				message = [OSCMessage createWithAddress:@"/vel_forward"];
			}else{
				_rotation += 25;
				message = [OSCMessage createWithAddress:@"/vel_backward"];
			}
			break;
		case OP_MODE_ROTATION:
			if (rotFrag) {
				_rotation -= 25;
				message = [OSCMessage createWithAddress:@"/vel_ccw"];
			}else{
				_rotation += 25;
				message = [OSCMessage createWithAddress:@"/vel_cw"];
			}
			break;
		default:
			break;
	}

	
	_preState = state;
	
	//[message addInt:_rotation];
	[_outPort sendThisPacket:[OSCPacket createWithContent:message]];
	
	self.label_value.text =[NSString stringWithFormat:@"%d",_rotation];
}

-(int)checkEncoderState{
	/*
	 pin6:pin7 = state
	 0:0 = 0 :0b00
	 0:1 = 1 :0b01
	 1:0 = 2 :0b10
	 1:1 = 3 :0b11
	*/
	int pin6 = [Konashi digitalRead:PIO6];
	int pin7 = [Konashi digitalRead:PIO7];
	
	return pin6 * 2 + pin7;
}

-(void)disconnect
{
	NSLog(@"konashi disconnect");
}

-(void)text_host_update:(UITextField*)field{
	_host = field.text;
	NSLog(@"host:%@",_host);
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField{
	[textField resignFirstResponder];
	return YES;
}

-(BOOL)buttonPushed:(UIButton*)button{
	//konashi
	if([Konashi find]){
		NSLog(@"success ot konashi connect");
	}else{
		NSLog(@"fail to konashi connect");
	};
	
	//osc接続
	NSLog(@"connect to %@",_host);
	_outPort = [_oscMan createNewOutputToAddress:_host atPort:[_port intValue]];
}

-(BOOL)stopButtonPushed:(UIButton*)button{
	OSCMessage *message;
	
	message = [OSCMessage createWithAddress:@"/vel_stop"];
	
	[_outPort sendThisPacket:[OSCPacket createWithContent:message]];
}

-(BOOL)opButtonPushed:(UIButton*)button{
	switch (_opMode) {
		case OP_MODE_MOVE:
			_opMode = OP_MODE_ROTATION;
			NSLog(@"operation:move");
			break;
		case OP_MODE_ROTATION:
			_opMode = OP_MODE_MOVE;
			NSLog(@"operation:rot");
			break;
		default:
			break;
	}
}
@end
