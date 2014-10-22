/*
 ******************************************************************************
 * Copyright (C) 2014-2017 Elsevier/Mendeley.
 *
 * This file is part of the Mendeley iOS SDK.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *****************************************************************************
 */

#import "MendeleyDocumentsAPI.h"
#import "MendeleyDocument.h"
#import "MendeleyKitConfiguration.h"
#import "NSDictionary+Merge.h"

@implementation MendeleyDocumentsAPI
#pragma mark Private methods

- (NSDictionary *)defaultServiceRequestHeaders
{
    return @{ kMendeleyRESTRequestAccept: kMendeleyRESTRequestJSONDocumentType };
}

- (NSDictionary *)defaultUploadRequestHeaders
{
    return @{ kMendeleyRESTRequestAccept: kMendeleyRESTRequestJSONDocumentType,
              kMendeleyRESTRequestContentType : kMendeleyRESTRequestJSONDocumentType };
}

- (NSDictionary *)defaultQueryParameters
{
    return [[MendeleyDocumentParameters new] valueStringDictionary];
}

- (NSDictionary *)defaultQueryParametersWithoutViewParameter
{
    MendeleyDocumentParameters *params = [MendeleyDocumentParameters new];

    params.view = nil;
    return [params valueStringDictionary];
}

- (NSDictionary *)defaultViewQueryParameters
{
    MendeleyDocumentParameters *params = [MendeleyDocumentParameters new];

    if (nil != params.view)
    {
        return @{ @"view" : params.view };
    }
    return nil;
}

- (NSDictionary *)defaultCatalogViewQueryParameters
{
    MendeleyCatalogParameters *params = [MendeleyCatalogParameters new];

    if (nil != params.view)
    {
        return @{ @"view" : params.view };
    }
    return nil;
}

#pragma mark -

- (void)documentListWithLinkedURL:(NSURL *)linkURL
                  completionBlock:(MendeleyArrayCompletionBlock)completionBlock
{
    [NSError assertArgumentNotNil:linkURL argumentName:@"linkURL"];
    [NSError assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];

    [self.provider invokeGET:linkURL
                         api:nil
           additionalHeaders:[self defaultServiceRequestHeaders]
             queryParameters:nil       // we don't need to specify parameters because are inehrits from the previous call
      authenticationRequired:YES
             completionBlock: ^(MendeleyResponse *response, NSError *error) {
         MendeleyBlockExecutor *blockExec = [[MendeleyBlockExecutor alloc] initWithArrayCompletionBlock:completionBlock];
         if (![self.helper isSuccessForResponse:response error:&error])
         {
             [blockExec executeWithArray:nil syncInfo:nil error:error];
         }
         else
         {
             MendeleyModeller *jsonModeller = [MendeleyModeller sharedInstance];
             [jsonModeller parseJSONData:response.responseBody
                            expectedType:kMendeleyModelDocument
                         completionBlock: ^(NSArray *documents, NSError *parseError) {
                  if (nil != parseError)
                  {
                      [blockExec executeWithArray:nil
                                         syncInfo:nil
                                            error:parseError];
                  }
                  else
                  {
                      [blockExec executeWithArray:documents
                                         syncInfo:response.syncHeader
                                            error:nil];
                  }
              }];
         }
     }];
}

- (void)documentListWithQueryParameters:(MendeleyDocumentParameters *)queryParameters
                        completionBlock:(MendeleyArrayCompletionBlock)completionBlock
{
    NSDictionary *query = [queryParameters valueStringDictionary];

    [self.helper mendeleyObjectListOfType:kMendeleyModelDocument
                                      api:kMendeleyRESTAPIDocuments
                               parameters:[NSDictionary dictionaryByMerging:query with:[self defaultQueryParameters]]
                        additionalHeaders:[self defaultServiceRequestHeaders]
                          completionBlock:completionBlock];
}

- (void)documentWithDocumentID:(NSString *)documentID
               completionBlock:(MendeleyObjectCompletionBlock)completionBlock
{
    [NSError assertArgumentNotNil:documentID argumentName:@"documentID"];
    NSString *apiEndpoint = [NSString stringWithFormat:kMendeleyRESTAPIDocumentWithID, documentID];
    [self.helper mendeleyObjectOfType:kMendeleyModelDocument
                           parameters:[self defaultViewQueryParameters]
                                  api:apiEndpoint
                    additionalHeaders:[self defaultServiceRequestHeaders]
                      completionBlock:completionBlock];
}

- (void)catalogDocumentWithCatalogID:(NSString *)catalogID
                     completionBlock:(MendeleyObjectCompletionBlock)completionBlock
{
    [NSError assertArgumentNotNil:catalogID argumentName:@"catalogID"];
    NSString *apiEndpoint = [NSString stringWithFormat:kMendeleyRESTAPICatalogWithID, catalogID];
    [self.helper mendeleyObjectOfType:kMendeleyModelCatalogDocument
                           parameters:[self defaultCatalogViewQueryParameters]
                                  api:apiEndpoint
                    additionalHeaders:[self defaultServiceRequestHeaders]
                      completionBlock:completionBlock];
}

- (void)catalogDocumentWithParameters:(MendeleyCatalogParameters *)queryParameters
                      completionBlock:(MendeleyArrayCompletionBlock)completionBlock
{
    NSDictionary *query = [queryParameters valueStringDictionary];

    [self.helper mendeleyObjectListOfType:kMendeleyModelCatalogDocument
                                      api:kMendeleyRESTAPICatalog
                               parameters:query
                        additionalHeaders:[self defaultServiceRequestHeaders]
                          completionBlock:completionBlock];
}

- (void)createDocument:(MendeleyDocument *)mendeleyDocument
       completionBlock:(MendeleyObjectCompletionBlock)completionBlock
{
    [self.helper createMendeleyObject:mendeleyDocument
                                  api:kMendeleyRESTAPIDocuments
                    additionalHeaders:[self defaultUploadRequestHeaders]
                         expectedType:kMendeleyModelDocument
                      completionBlock:completionBlock];
}

- (void)updateDocument:(MendeleyDocument *)updatedMendeleyDocument
       completionBlock:(MendeleyObjectCompletionBlock)completionBlock
{
    [NSError assertArgumentNotNil:updatedMendeleyDocument argumentName:@"updatedMendeleyDocument"];
    NSString *apiEndpoint = [NSString stringWithFormat:kMendeleyRESTAPIDocumentWithID, updatedMendeleyDocument.object_ID];
    [self.helper updateMendeleyObject:updatedMendeleyDocument
                                  api:apiEndpoint
                    additionalHeaders:[self defaultUploadRequestHeaders]
                         expectedType:kMendeleyModelDocument
                      completionBlock:completionBlock];
}

- (void)deleteDocumentWithID:(NSString *)documentID
             completionBlock:(MendeleyCompletionBlock)completionBlock
{
    [NSError assertArgumentNotNil:documentID argumentName:@"documentID"];
    NSString *apiEndpoint = [NSString stringWithFormat:kMendeleyRESTAPIDocumentWithID, documentID];
    [self.helper deleteMendeleyObjectWithAPI:apiEndpoint
                             completionBlock:completionBlock];
}

- (void)trashDocumentWithID:(NSString *)documentID
            completionBlock:(MendeleyCompletionBlock)completionBlock
{
    [NSError assertArgumentNotNil:documentID argumentName:@"documentID"];
    [NSError assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    NSString *apiEndpoint = [NSString stringWithFormat:kMendeleyRESTAPIDocumentWithIDToTrash, documentID];
    [self.provider invokePOST:self.baseURL
                          api:apiEndpoint
            additionalHeaders:[self defaultServiceRequestHeaders]
               bodyParameters:nil
                       isJSON:NO
       authenticationRequired:YES
              completionBlock: ^(MendeleyResponse *response, NSError *error) {
         MendeleyBlockExecutor *blockExec = [[MendeleyBlockExecutor alloc] initWithCompletionBlock:completionBlock];
         if (![self.helper isSuccessForResponse:response error:&error])
         {
             [blockExec executeWithBool:NO error:error];
         }
         else
         {
             [blockExec executeWithBool:YES error:nil];
         }
     }];
}

- (void)deletedDocumentsSince:(NSDate *)deletedSince
              completionBlock:(MendeleyArrayCompletionBlock)completionBlock
{
    [NSError assertArgumentNotNil:deletedSince argumentName:@"deletedSince"];
    [NSError assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    NSString *deletedSinceString = [[MendeleyObjectHelper jsonDateFormatter] stringFromDate:deletedSince];
    NSDictionary *query = @{ kMendeleyRESTAPIQueryDeletedSince : deletedSinceString };
    [self.provider invokeGET:self.baseURL
                         api:kMendeleyRESTAPIDocuments
           additionalHeaders:[self defaultServiceRequestHeaders]
             queryParameters:[NSDictionary dictionaryByMerging:query with:[self defaultQueryParametersWithoutViewParameter]]
      authenticationRequired:YES
             completionBlock: ^(MendeleyResponse *response, NSError *error) {
         MendeleyBlockExecutor *blockExec = [[MendeleyBlockExecutor alloc] initWithArrayCompletionBlock:completionBlock];
         if (![self.helper isSuccessForResponse:response error:&error])
         {
             [blockExec executeWithArray:nil syncInfo:nil error:error];
         }
         else
         {
             MendeleyModeller *jsonModeller = [MendeleyModeller sharedInstance];
             id jsonData = response.responseBody;
             if ([jsonData isKindOfClass:[NSArray class]])
             {
                 NSArray *jsonArray = (NSArray *) jsonData;
                 [jsonModeller parseJSONArrayOfIDDictionaries:jsonArray completionBlock: ^(NSArray *arrayOfStrings, NSError *parseError) {
                      if (nil != parseError)
                      {
                          [blockExec executeWithArray:nil syncInfo:nil error:parseError];
                      }
                      else
                      {
                          [blockExec executeWithArray:arrayOfStrings syncInfo:response.syncHeader error:nil];
                      }
                  }];
             }
         }
     }];
}

- (void)trashedDocumentListWithLinkedURL:(NSURL *)linkURL
                         completionBlock:(MendeleyArrayCompletionBlock)completionBlock
{
    [NSError assertArgumentNotNil:linkURL argumentName:@"linkURL"];
    [NSError assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    [self.provider invokeGET:linkURL
                         api:nil
           additionalHeaders:[self defaultServiceRequestHeaders]
             queryParameters:[self defaultQueryParameters]
      authenticationRequired:YES
             completionBlock: ^(MendeleyResponse *response, NSError *error) {
         MendeleyBlockExecutor *blockExec = [[MendeleyBlockExecutor alloc] initWithArrayCompletionBlock:completionBlock];
         if (![self.helper isSuccessForResponse:response error:&error])
         {
             [blockExec executeWithArray:nil syncInfo:nil error:error];
         }
         else
         {
             MendeleyModeller *jsonModeller = [MendeleyModeller sharedInstance];
             [jsonModeller parseJSONData:response.responseBody expectedType:kMendeleyModelDocument completionBlock: ^(NSArray *documents, NSError *parseError) {
                  if (nil != parseError)
                  {
                      [blockExec executeWithArray:nil syncInfo:nil error:parseError];
                  }
                  else
                  {
                      [blockExec executeWithArray:documents syncInfo:response.syncHeader error:nil];
                  }
              }];
         }
     }];
}

- (void)trashedDocumentListWithQueryParameters:(MendeleyDocumentParameters *)queryParameters
                               completionBlock:(MendeleyArrayCompletionBlock)completionBlock
{
    NSDictionary *query = [queryParameters valueStringDictionary];

    [self.helper mendeleyObjectListOfType:kMendeleyModelDocument
                                      api:kMendeleyRESTAPITrashedDocuments
                               parameters:[NSDictionary dictionaryByMerging:query with:[self defaultQueryParameters]]
                        additionalHeaders:[self defaultServiceRequestHeaders]
                          completionBlock:completionBlock];
}

- (void)deleteTrashedDocumentWithID:(NSString *)documentID
                    completionBlock:(MendeleyCompletionBlock)completionBlock
{
    [NSError assertArgumentNotNil:documentID argumentName:@"documentID"];
    NSString *apiEndpoint = [NSString stringWithFormat:kMendeleyRESTAPITrashedDocumentWithID, documentID];
    [self.helper deleteMendeleyObjectWithAPI:apiEndpoint
                             completionBlock:completionBlock];
}

- (void)restoreTrashedDocumentWithID:(NSString *)documentID
                     completionBlock:(MendeleyCompletionBlock)completionBlock
{
    [NSError assertArgumentNotNil:documentID argumentName:@"documentID"];
    [NSError assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    NSString *apiEndpoint = [NSString stringWithFormat:kMendeleyRESTAPIRestoreTrashedDocumentWithID, documentID];
    [self.provider invokePOST:self.baseURL
                          api:apiEndpoint
            additionalHeaders:nil
               bodyParameters:nil
                       isJSON:NO
       authenticationRequired:YES
              completionBlock: ^(MendeleyResponse *response, NSError *error) {
         MendeleyBlockExecutor *blockExec = [[MendeleyBlockExecutor alloc] initWithCompletionBlock:completionBlock];
         if (![self.helper isSuccessForResponse:response error:&error])
         {
             [blockExec executeWithBool:NO error:error];
         }
         else
         {
             [blockExec executeWithBool:YES error:nil];
         }
     }];
}

- (void)trashedDocumentWithDocumentID:(NSString *)documentID
                      completionBlock:(MendeleyObjectCompletionBlock)completionBlock
{
    [NSError assertArgumentNotNil:documentID argumentName:@"documentID"];
    NSString *apiEndpoint = [NSString stringWithFormat:kMendeleyRESTAPITrashedDocumentWithID, documentID];
    [self.helper mendeleyObjectOfType:kMendeleyModelDocument
                           parameters:[self defaultViewQueryParameters]
                                  api:apiEndpoint
                    additionalHeaders:[self defaultServiceRequestHeaders]
                      completionBlock:completionBlock];
}

- (void)documentTypesWithCompletionBlock:(MendeleyArrayCompletionBlock)completionBlock
{
    [self.helper mendeleyObjectListOfType:kMendeleyModelDocumentType
                                      api:kMendeleyRESTAPIDocumentTypes
                               parameters:nil
                        additionalHeaders:nil
                          completionBlock:completionBlock];
}

- (void)identifierTypesWithCompletionBlock:(MendeleyArrayCompletionBlock)completionBlock
{
    [self.helper mendeleyObjectListOfType:kMendeleyModelIdentifierType
                                      api:kMendeleyRESTAPIIdentifierTypes
                               parameters:nil
                        additionalHeaders:nil
                          completionBlock:completionBlock];
}

@end
