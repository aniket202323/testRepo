 CREATE  PROCEDURE dbo.spLocal_XCAddLogMessage  
 @ServiceDesc  VarChar(50),   
 @TimeStamp  DateTime,   
 @Msg   VarChar(8000),   
 @MsgTimeStamp DateTime  
AS  
-------------------------------------------------------------------------------  
-- Call SpServer that evaluates the message to decide if it should add message  
-- to the Proficy Server_Log_Records table  
-- TimeStamp : is the Log file creation time  
-- MsgTimeStamp: is the timestamp for the event being reported occured  
-------------------------------------------------------------------------------  
EXEC spServer_CmnAddLogMessage @ServiceDesc, @TimeStamp, @Msg, @MsgTimeStamp  
  
  
