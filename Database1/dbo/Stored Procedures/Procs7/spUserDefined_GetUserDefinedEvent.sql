
CREATE PROCEDURE dbo.spUserDefined_GetUserDefinedEvent @EventId INT

 AS
BEGIN

    SELECT ude.UDE_Id AS                                               EventId,
           ude.Ack,
           ude.Ack_By AS                                               AckUserId,
           userAckBy.Username AS                                       AckUserName,
           ude.Ack_On AS                                               AckTime,
           ude.Action_Comment_Id AS                                    ActionCommentId,
           ude.Action1 AS                                              Action1Id,
           action1.Event_Reason_Name AS                                Action1Name,
           ude.Action2 AS                                              Action2Id,
           action2.Event_Reason_Name AS                                Action2Name,
           ude.Action3 AS                                              Action3Id,
           action3.Event_Reason_Name AS                                Action3Name,
           ude.Action4 AS                                              Action4Id,
           action4.Event_Reason_Name AS                                Action4Name,
           ude.Cause_Comment_Id AS                                     CauseCommentId,
           ude.Cause1 AS                                               Cause1Id,
           cause1.Event_Reason_Name AS                                 Cause1Name,
           ude.Cause2 AS                                               Cause2Id,
           cause2.Event_Reason_Name AS                                 Cause2Name,
           ude.Cause3 AS                                               Cause3Id,
           cause3.Event_Reason_Name AS                                 Cause3Name,
           ude.Cause4 AS                                               Cause4Id,
           cause4.Event_Reason_Name AS                                 Cause4Name,
           ude.Comment_Id AS                                           CommentId,
           ude.Duration,
           dbo.fnserver_CmnConvertFromDbTime(ude.End_Time, 'UTC') AS   EndTime,
     -- End_Time_Ms,
           ude.Event_Id AS                                             ProductionEventId,
           ude.Event_Reason_Tree_Data_Id AS                            ReasonTreeDataId,
           ude.Event_Subtype_Id AS                                     EventSubtypeId,
           ude.PU_Id AS                                                PUId,
           ude.Research_Close_Date AS                                  ResearchCloseDate,
           ude.Research_Comment_Id AS                                  ResearchCommentId,
           ude.Research_Open_Date AS                                   ResearchOpenDate,
           ude.Research_Status_Id AS                                   ResearchStatusId,
           rs.Research_Status_Desc AS                                  ResearchStatusName,
           ude.Research_User_Id AS                                     ResearchUserId,
           userResearch.Username AS                                    ResearchUserName,
           ude.Signature_Id AS                                         ESignatureId,
           dbo.fnserver_CmnConvertFromDbTime(ude.Start_Time, 'UTC') AS StartTime,
           ude.UDE_Desc AS                                             UDEDescription,
           ude.User_Id AS                                              UserId,
           user1.Username AS                                           UserName,
           ude.Conformance,
           ude.Event_Status AS                                         EventStatus,
           S.ProdStatus_Desc AS                                        EventStatusDesc,
           ISNULL(S.LockData, 0) AS                                    IsLockEventData,
           ude.Testing_Prct_Complete AS                                TestPercentComplete,
           ude.Testing_Status AS                                       TestingStatus
           FROM User_Defined_Events AS ude
                LEFT JOIN Production_Status AS S ON S.ProdStatus_Id = UDE.Event_Status
                LEFT JOIN Event_Reasons AS cause1 ON ude.Cause1 = cause1.Event_Reason_Id
                LEFT JOIN Event_Reasons AS cause2 ON ude.Cause2 = cause2.Event_Reason_Id
                LEFT JOIN Event_Reasons AS cause3 ON ude.Cause3 = cause3.Event_Reason_Id
                LEFT JOIN Event_Reasons AS cause4 ON ude.Cause4 = cause4.Event_Reason_Id
                LEFT JOIN Event_Reasons AS action1 ON ude.Action1 = action1.Event_Reason_Id
                LEFT JOIN Event_Reasons AS action2 ON ude.Action2 = action2.Event_Reason_Id
                LEFT JOIN Event_Reasons AS action3 ON ude.Action3 = action3.Event_Reason_Id
                LEFT JOIN Event_Reasons AS action4 ON ude.Action4 = action4.Event_Reason_Id
                LEFT JOIN Users AS user1 ON user1.User_Id = ude.User_Id
                LEFT JOIN Users AS userAckBy ON userAckBy.User_Id = ude.Ack_By
                LEFT JOIN Users AS userResearch ON userResearch.User_Id = ude.Research_User_Id
                LEFT JOIN Research_Status AS rs ON rs.Research_Status_Id = ude.Research_Status_Id
           WHERE UDE_Id = @EventId
END
