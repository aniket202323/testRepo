CREATE  	 PROCEDURE dbo.spCmn_GetEmailMessage
@MessageId INT
-------------------------------------------------------------------------------
-- This SP was originally developed for the Production Schedule Biztalk
-- Orchestration. It looks up an Email Message Code table for a descripion 
-- for the error passed as an input parameter and returns the message text
-- and the email recipients for the text. 
-------------------------------------------------------------------------------
-- DATE 	  	  	 BY 	  	  	  	 DESCRIPTION
-- 	  	  	  	 Alex Metlitski  01 01   Initial development
-- 18-Oct-2005 	 Alex Judkowicz 	 01 02 	 Add Header
-- 	  	  	  	 Alex Metlistski  	  	 Add support for phase 2
-- 19-Jan-2006  Ahmir Hussain 	  	  	 Productized Version 	 
-- 06-Mar-2006  Ahmir Hussain 	  	  	 Added Severity Field 	 
-- 16-Mar-2006  Ahmir Hussain 	  	  	 Set Severity to 2(Warning) if Message does not exist
-- EXECUTE spCmn_GetEmailMessage -101
-------------------------------------------------------------------------------
AS
-------------------------------------------------------------------------------
-- Variable Declaration
-------------------------------------------------------------------------------
DECLARE  	 @MESSAGE  	 nVarChar(4000),
 	  	 @SUBJECT 	 nVarChar(4000)
DECLARE 	  	 @RecipientTable TABLE ( RowId 	 INT IDENTITY,
 	  	  	  	  	 Recipient_Email VarChar(255),
 	  	  	  	  	 Recipient_Desc VarChar(255))
DECLARE 	  	 @EmailGroupId INT,
                @EmailGroupDesc VARCHAR(100),
 	  	 @Severity INT
-------------------------------------------------------------------------------
-- Variable Initialization
-------------------------------------------------------------------------------
SELECT @MESSAGE = NULL, 
       @SUBJECT = NULL,
       @EmailGroupId = NULL,
       @EmailGroupDesc = NULL,
       @Severity = NULL
-------------------------------------------------------------------------------
-- Process the Message Code   
-------------------------------------------------------------------------------
IF EXISTS(SELECT MESSAGE_ID FROM EMAIL_MESSAGE_DATA WHERE MESSAGE_ID = @MessageId)
  BEGIN
 	 SELECT  	 @MESSAGE = isnull(convert(nVarChar(4000),MESSAGE_TEXT),'NO TEXT FOR @MESSAGEID: ' + cast(@MessageId as varChar(10))),
 	  	  	 @SUBJECT = isnull(convert(nVarChar(4000),MESSAGE_SUBJECT),'NO SUBJECT FOR @MESSAGEID: ' + CAST(@MessageId AS VARCHAR(10))),
 	  	  	 @EmailGroupId = isnull(emd.EG_ID,''),
 	  	  	 @EmailGroupDesc = isnull(eg.eg_desc,'NO GROUP FOR @MESSAGEID: ' + CAST(@MessageId AS VARCHAR(10))),
 	         @MessageId = emd.MESSAGE_ID,
 	  	  	 @Severity = emd.SEVERITY         
 	 FROM  	 EMAIL_MESSAGE_DATA emd 
    LEFT JOIN EMAIL_GROUPS eg
 	 ON      emd.eg_id = eg.eg_id
 	 WHERE  	 MESSAGE_ID = @MessageId
    IF 	 @EmailGroupId is NOT NULL
           BEGIN
                	 INSERT INTO @RecipientTable (Recipient_Email, Recipient_Desc)
                	 SELECT er.ER_Address, er.Er_desc
 	  	  	  	 FROM email_recipients er 
 	  	  	  	 LEFT JOIN email_groups_data egd
 	  	  	  	 ON  egd.er_id = er.er_id
 	  	  	  	 WHERE eg_id = @EmailGroupId 
 	  	  	 END 
        --ELSE                                     -- ONLY NEEDED IF WE DON'T DO isnull(EG_ID,'')
        --   BEGIN
        --       INSERT INTO @RecipientTable (Recipient_Email, Recipient_Desc)  
 	 --       VALUES ('NO EMAIL GROUP SPECIFIED', 'N/A')
        --   END          
  END
ELSE
  BEGIN     -- MessageId does not exist   
 	 SELECT  	 @MESSAGE = 'NO TEXT FOR @MESSAGEID: ' + CAST(@MessageId AS VARCHAR(10)),
 	  	  	 @SUBJECT = 'NO SUBJECT FOR @MESSAGEID: ' + CAST(@MessageId AS VARCHAR(10)),
 	  	  	 @EmailGroupDesc = 'NO GROUP FOR @MESSAGEID: ' + CAST(@MessageId AS VARCHAR(10)),
 	  	  	 @Severity = 2 -- Warning
  END
-------------------------------------------------------------------------------
-- Return the Message Code with Descriptions
-------------------------------------------------------------------------------
SELECT  @EmailGroupId AS MESSAGEGROUPID,
    	  	 @EmailGroupDesc AS MESSAGEGROUP,
 	  	 @SUBJECT AS SUBJECT, 
        @MESSAGE AS MESSAGE,
 	  	 @MESSAGEID AS MESSAGE_ID,
 	  	 @SEVERITY AS SEVERITY 
-------------------------------------------------------------------------------
-- Return the List of Recipients
-------------------------------------------------------------------------------
SELECT RowId, Recipient_Email, Recipient_Desc
FROM @RecipientTable
