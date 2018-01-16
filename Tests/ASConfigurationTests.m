//
//  ASConfigurationTests.m
//  AsyncDisplayKitTests
//
//  Created by Adlai on 1/14/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ASTestCase.h"
#import "ASConfiguration.h"
#import "ASConfigurationDelegate.h"
#import "ASConfigurationInternal.h"

@interface ASConfigurationTests : ASTestCase <ASConfigurationDelegate>

@end

@implementation ASConfigurationTests {
  void (^onActivate)(ASConfigurationTests *self, ASExperimentalFeatures feature);
}

- (void)testExperimentalFeatureConfig
{
  // Set the config
  ASConfiguration *config = [[ASConfiguration alloc] init];
  config.experimentalFeatures = ASExperimentalGraphicsContexts;
  config.delegate = self;
  [ASConfigurationManager test_resetWithConfiguration:config];
  
  // Set an expectation for a callback, and assert we only get one.
  XCTestExpectation *e = [self expectationWithDescription:@"Callback 1 done."];
  onActivate = ^(ASConfigurationTests *self, ASExperimentalFeatures feature) {
    XCTAssertEqual(feature, ASExperimentalGraphicsContexts);
    [e fulfill];
    // Next time it's a fail.
    self->onActivate = ^(ASConfigurationTests *self, ASExperimentalFeatures feature) {
      XCTFail(@"Too many callbacks.");
    };
  };
  
  // Now activate the graphics experiment and expect it works.
  XCTAssertTrue(ASActivateExperimentalFeature(ASExperimentalGraphicsContexts));
  // We should get a callback here
  // Now activate text node and expect it fails.
  XCTAssertFalse(ASActivateExperimentalFeature(ASExperimentalTextNode));
  [self waitForExpectationsWithTimeout:3 handler:nil];
}

- (void)textureDidActivateExperimentalFeatures:(ASExperimentalFeatures)feature
{
  if (onActivate) {
    onActivate(self, feature);
  }
}

- (void)testMappingNamesToFlags
{
  // Throw in a bad bit.
  ASExperimentalFeatures features = ASExperimentalTextNode | ASExperimentalGraphicsContexts | (1 << 22);
  NSArray *expectedNames = @[ @"exp_graphics_contexts", @"exp_text_node" ];
  XCTAssertEqualObjects(expectedNames, ASExperimentalFeaturesGetNames(features));
}

- (void)testMappingFlagsFromNames
{
  // Throw in a bad name.
  NSArray *names = @[ @"exp_text_node", @"exp_graphics_contexts", @"__invalid_name" ];
  ASExperimentalFeatures expected = ASExperimentalGraphicsContexts | ASExperimentalTextNode;
  XCTAssertEqual(expected, ASExperimentalFeaturesFromArray(names));
}

@end
