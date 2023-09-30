-------------------------------------------------------------------------------
-- 
--
-- 2002-07-26 	 Alex Judkowicz 	 Original
-------------------------------------------------------------------------------
CREATE PROCEDURE dbo.spCmn_AddMessage 
 	 @Message 	  	 nVarChar(4000),
 	 @ObjectName 	  	 nVarChar(255),
 	 @RefId 	  	  	 Int = Null,
 	 @TimeStamp 	  	 DateTime = Null,
 	 @ClientConnectionId 	 Int = Null,
 	 @Type 	  	  	 Int = Null 
AS
DECLARE @MessageInfo 	  	 nVarChar(255),
 	 @MessageLogId 	  	 Int
-------------------------------------------------------------------------------
-- Populate Message Header table
-------------------------------------------------------------------------------
SELECT 	 @MessageInfo = 'OBJ:' +  @ObjectName + ' | RefId:' + 
 	 Coalesce(Convert(VarChar(10),@RefId),'0')
INSERT 	 Message_Log_Header (Timestamp, Client_Connection_Id, Type, Message_Info)
 	 VALUES (Coalesce(@TimeStamp, dbo.fnServer_CmnGetDate(getUTCdate())), @ClientConnectionId, @Type, 
 	 @MessageInfo)
SELECT 	 @MessageLogId = Scope_Identity()
-------------------------------------------------------------------------------
-- Populate Message detail table
-------------------------------------------------------------------------------
INSERT 	 Message_Log_Detail (Message_Log_Id, Message)
 	 VALUES 	 (@MessageLogId, @Message)
ReturnControl:
 	 RETURN
