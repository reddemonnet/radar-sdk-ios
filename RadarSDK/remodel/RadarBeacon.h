/**
 * This file is generated using the remodel generation script.
 * The name of the input file is RadarBeacon.value
 */

#import "RadarJSONCoding.h"
#import "RadarLocation.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * This is a test data class for auto generation code
 */
@interface RadarBeacon : NSObject<RadarJSONCoding, NSCopying, NSCoding>

/**
 * This is nonnull property.
 */
@property (nonatomic, readonly, copy) NSString *_id;
/**
 * This is a nullable property.
 */
@property (nonatomic, readonly, copy, nullable) NSString *_description;
/**
 * This is collection with generic type
 */
@property (nonatomic, readonly, copy) NSDictionary<NSString *, NSNumber *> *numberMetadata;
/**
 * This is collection without generic type
 */
@property (nonatomic, readonly, copy) NSArray<NSString *> *metadataArray;
/**
 * This is another Radar model class (it must conforms to RadarJSONCODding)
 */
@property (nonatomic, readonly, copy) RadarLocation *location;
/**
 * This is an arrry of another Radar model class
 */
@property (nonatomic, readonly, copy) NSArray<RadarLocation *> *locationArray;
@property (nonatomic, readonly, copy) NSNumber *version;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

/**
 * @param _id This is nonnull property.
 * @param _description This is a nullable property.
 * @param numberMetadata This is collection with generic type
 * @param metadataArray This is collection without generic type
 * @param location This is another Radar model class (it must conforms to RadarJSONCODding)
 * @param locationArray This is an arrry of another Radar model class
 */
- (instancetype)initWith_id:(NSString *)_id
               _description:(nullable NSString *)_description
             numberMetadata:(NSDictionary<NSString *, NSNumber *> *)numberMetadata
              metadataArray:(NSArray<NSString *> *)metadataArray
                   location:(RadarLocation *)location
              locationArray:(NSArray<RadarLocation *> *)locationArray
                    version:(NSNumber *)version NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END