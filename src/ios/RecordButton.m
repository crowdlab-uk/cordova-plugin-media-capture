//
//  RecordButton.m
//  Engage
//
//  Created by Thomas Lee on 18/10/2019.
//

#import "RecordButton.h"

@implementation RecordButton

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

- (void)layoutSubviews {
  [super layoutSubviews];
  [self updateCornerRadius];
}

- (void)updateCornerRadius {
  if (self.isSelected) {
    [self.layer setCornerRadius: 0];
  } else {
    [self.layer setCornerRadius: self.frame.size.height / 2];
  }
}

@end
