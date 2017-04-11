//
//  MendeleySharesAPI.m
//  MendeleyKit
//
//  Created by Trevisi, Luigi (ELS) on 25/01/2017.
//  Copyright © 2017 Mendeley. All rights reserved.
//

#import "MendeleySharesAPI.h"

@implementation MendeleySharesAPI

- (NSDictionary *)defaultServiceRequestHeaders
{
    return @{
             kMendeleyRESTRequestContentType: kMendeleyRESTRequestJSONNewsItemsShareType
             };
}

- (NSDictionary *)shareDocumentServiceRequestHeaders
{
    return @{
             kMendeleyRESTRequestContentType: kMendeleyRESTRequestJSONDocumentShareType
             };
}

- (void)shareFeedWithQueryParameters:(MendeleySharesParameters *)queryParameters
                                task:(MendeleyTask *)task
                     completionBlock:(MendeleyCompletionBlock)completionBlock
{
    [self.provider invokePOST:self.baseURL
                          api:kMendeleyRESTAPIShareFeed
            additionalHeaders:[self defaultServiceRequestHeaders]
               bodyParameters:[queryParameters valueStringDictionary]
                       isJSON:YES
       authenticationRequired:YES
                         task:task
              completionBlock:^(MendeleyResponse * _Nullable response, NSError * _Nullable error) {
        MendeleyBlockExecutor *blockExec = [[MendeleyBlockExecutor alloc] initWithCompletionBlock:completionBlock];
        BOOL success = [self.helper isSuccessForResponse:response error:&error];
        [blockExec executeWithBool:success error:error];
              }];
}

- (void)shareDocumentWithDocumentID:(NSString *)documentID
                               task:(MendeleyTask *)task
                    completionBlock:(MendeleyCompletionBlock)completionBlock
{
    MendeleyShareDocumentParameters *parameters = [MendeleyShareDocumentParameters new];
    parameters.document_id = documentID;
    [self shareDocumentWithQueryParameters:parameters
                                      task:task
                           completionBlock:completionBlock];
}

- (void)shareDocumentWithDOI:(NSString *)doi
                        task:(MendeleyTask *)task
             completionBlock:(MendeleyCompletionBlock)completionBlock
{
    MendeleyShareDocumentParameters *parameters = [MendeleyShareDocumentParameters new];
    parameters.doi = doi;
    [self shareDocumentWithQueryParameters:parameters
                                      task:task
                           completionBlock:completionBlock];
}

- (void)shareDocumentWithScopus:(NSString *)scopus
                           task:(MendeleyTask *)task
                completionBlock:(MendeleyCompletionBlock)completionBlock
{
    MendeleyShareDocumentParameters *parameters = [MendeleyShareDocumentParameters new];
    parameters.scopus = scopus;
    [self shareDocumentWithQueryParameters:parameters
                                      task:task
                           completionBlock:completionBlock];
}

- (void)shareDocumentWithQueryParameters:(MendeleyShareDocumentParameters *)queryParameters
                                    task:(MendeleyTask *)task
                         completionBlock:(MendeleyCompletionBlock)completionBlock
{
    [self.provider invokePOST:self.baseURL
                          api:kMendeleyRESTAPIShareFeed
            additionalHeaders:[self shareDocumentServiceRequestHeaders]
               bodyParameters:[queryParameters valueStringDictionary]
                       isJSON:YES
       authenticationRequired:YES
                         task:task
              completionBlock:^(MendeleyResponse * _Nullable response, NSError * _Nullable error) {
                  MendeleyBlockExecutor *blockExec = [[MendeleyBlockExecutor alloc] initWithCompletionBlock:completionBlock];
                  BOOL success = [self.helper isSuccessForResponse:response error:&error];
                  [blockExec executeWithBool:success error:error];
              }];
}

@end
