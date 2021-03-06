
#import "RACDemoViewController.h"
#import <ReactiveObjC.h>

@interface RACDemoViewController ()<UITextFieldDelegate>

@property (strong, nonatomic) UILabel *testLable;
@property (strong, nonatomic) UIButton *testButton;
@property (strong, nonatomic) UITextField *testTextField;

@end

@implementation RACDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //普通按钮点击事件响应
    [self normalButton_targetAction];
    
    //RAC按钮点击事件响应
    [self RACButton_targetAction];
    
    //使用KVO监听属性
    [self KVO_method];
    
    //RAC替代KVO方法
    [self RAC_KVO];
    
    //RAC替代delegate使用方法
    [self RACTextFieldDelegate];
    
    //RAC替代通知使用方法
    [self RACNotification];
    
    //RAC遍历字典、数组
    [self RACSequence];
    
    //RAC基本使用方法
    [self RACBase];
    
    //RAC map映射
    [self flattenMap];
    
    //RAC filter过滤
    [self RACfilter];
    
    [self ignoreValue];
    
    //RAC 过滤变换信号
    [self distinctUntilChanged];
    
    // Do any additional setup after loading the view from its nib.
}

- (void)flattenMap {
    [[self.testTextField.rac_textSignal flattenMap:^__kindof RACSignal * _Nullable(NSString * _Nullable value) {

        //自定义返回内容
        return [RACReturnSignal return:[NSString stringWithFormat:@"自定义了返回信号：%@",value]];
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
        NSLog(@"%@",NSStringFromClass([x class]));
    }];
    
    
    [[self.testTextField.rac_textSignal map:^id _Nullable(NSString * _Nullable value) {
        return [NSString stringWithFormat:@"map自定义了返回信号：%@",value];
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
        NSLog(@"%@",NSStringFromClass([x class]));
    }];
}

- (void)normalButton_targetAction
{
    [self.testButton addTarget:self action:@selector(tapAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)tapAction:(UIButton *)sender
{
    NSLog(@"按钮点击了");
    NSLog(@"%@",sender);
}

- (void)RACButton_targetAction
{
    [[self.testButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        NSLog(@"RAC按钮点击了");
        NSLog(@"%@",x);
    }];
    
    self.testLable.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]init];
    [self.testLable addGestureRecognizer:tap];
    [tap.rac_gestureSignal subscribeNext:^(__kindof UIGestureRecognizer * _Nullable x) {
        //点击事件响应的逻辑
        NSLog(@"%@",x);
    }];
}

- (void)KVO_method
{
    [self.testLable addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"text"] && object == self.testLable) {
        NSLog(@"%@",change);
    }
}

- (void)RAC_KVO
{
    [RACObserve(self.testLable, text) subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
}

- (void)RACTextFieldDelegate
{
    [[self rac_signalForSelector:@selector(textFieldDidBeginEditing:) fromProtocol:@protocol(UITextFieldDelegate)] subscribeNext:^(RACTuple * _Nullable x) {
        NSLog(@"textField delegate == %@",x);
    }];
    self.testTextField.delegate = self;
}

- (void)RACNotification
{
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIKeyboardDidHideNotification object:nil] subscribeNext:^(NSNotification * _Nullable x) {
        NSLog(@"%@",x);
    }];
}

- (void)RACTimer
{
    //主线程中每两秒执行一次
    [[RACSignal interval:2.0 onScheduler:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSDate * _Nullable x) {
        NSLog(@"%@",x);
    }];
    //创建一个新线程
    [[RACSignal interval:1 onScheduler:[RACScheduler schedulerWithPriority:(RACSchedulerPriorityHigh) name:@" com.ReactiveCocoa.RACScheduler.mainThreadScheduler"]] subscribeNext:^(NSDate * _Nullable x) {
        
        NSLog(@"%@",[NSThread currentThread]);
    }];
}

- (void)RACSequence
{
    //遍历数组
    NSArray *racAry = @[@"rac1",@"rac2",@"rac3"];
    [racAry.rac_sequence.signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    //遍历字典
    NSDictionary *dict = @{@"name":@"dragon",@"type":@"fire",@"age":@"1000"};
    [dict.rac_sequence.signal subscribeNext:^(id  _Nullable x) {
        RACTwoTuple *tuple = (RACTwoTuple *)x;
        NSLog(@"key == %@, value == %@",tuple[0],tuple[1]);
    }];
}

- (void)RACBase
{
    //RAC基本使用方法与流程
    
    //1. 创建signal信号
    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        
        //subscriber并不是一个对象
        //3. 发送信号
        [subscriber sendNext:@"sendOneMessage"];
        
        //发送error信号
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:1001 userInfo:@{@"errorMsg":@"this is a error message"}];
        [subscriber sendError:error];
        
        //4. 销毁信号
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"signal已销毁");
        }];
    }];
    
    //2.1 订阅信号
    [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    //2.2 针对实际中可能出现的逻辑错误，RAC提供了订阅error信号
    [signal subscribeError:^(NSError * _Nullable error) {
        NSLog(@"%@",error);
    }];
}

- (void)RACfilter
{
    @weakify(self);
    [[self.testTextField.rac_textSignal filter:^BOOL(NSString * _Nullable value) {
        //过滤判断条件
        @strongify(self)
        if (self.testTextField.text.length >= 6) {
            self.testTextField.text = [self.testTextField.text substringToIndex:6];
            self.testLable.text = @"已经到6位了";
            self.testLable.textColor = [UIColor redColor];
        }
        return value.length <= 6;
        
    }] subscribeNext:^(NSString * _Nullable x) {
        //订阅逻辑区域
        NSLog(@"filter过滤后的订阅内容：%@",x);
    }];
}

- (void)ignoreValue {
//    @weakify(self);
    [[self.testTextField.rac_textSignal ignoreValues] subscribeNext:^(id  _Nullable x) {
        //将self.testTextField的所有textSignal全部过滤掉
    }];
    
    [[self.testTextField.rac_textSignal ignore:@"1"] subscribeNext:^(id  _Nullable x) {
        //将self.testTextField的textSignal中字符串为指定条件的信号过滤掉
    }];
}

- (void)distinctUntilChanged {
    RACSubject *subject = [RACSubject subject];
    [[subject distinctUntilChanged] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    [subject sendNext:@1111];
    [subject sendNext:@2222];
    [subject sendNext:@2222];
}

@end
