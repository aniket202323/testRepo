  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-22  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_WriteMessage  
Author:   Matthew Wells (MSI)  
Date Created:  08/01/01  
  
Description:  
=========  
  
Change Date Who What  
=========== ==== =====  
*/  
  
  
CREATE PROCEDURE dbo.spLocal_WriteMessage  
@Stored_Procedure_Name varchar(100),  
@Message   varchar(8000)  
AS  
SET NOCOUNT ON  
  
DECLARE @File_Name   varchar(50),  
 @File_Path   varchar(25),  
 @File_Path_Temp   varchar(25),  
 @Move_Mask   varchar(25),  
 @TimeStamp   datetime,  
 @File_Write   varchar(1),  
 @File_Write_Parm_Id  int,  
 @File_Write_Parm_Name varchar(50),  
 @File_Write_Limit  int  
  
DECLARE @FileOutput TABLE(  
 Result_Set_Type  int DEFAULT 50,  
 File_Number   int DEFAULT 1,  
 File_Name  varchar(255) NULL,   
 Field_Number  int IDENTITY,  
 Field_Name  varchar(20) DEFAULT '0',  
 Field_Type        varchar(20) DEFAULT 'Alpha',  
 Field_Length  int NULL,  
 Field_Precision  int DEFAULT 1,  
 Field_Value  varchar(255) NULL,  
 Field_CR  int DEFAULT 0,  
 Field_Build_Path varchar(50) NULL,  
 Field_Final_Path varchar(50) NULL,  
 Field_Move_Mask  varchar(50) NULL,  
 Add_Timestamp  int DEFAULT 0  
)  
  
/***********************************************************************************************************************  
*                                           Initialization                                                             *  
***********************************************************************************************************************/  
SELECT  @File_Name   = 'CalcMsgs.log',  
 @File_Path_Temp   = 'C:\',  
 @Move_Mask   = 'CalcMsgs.log',  
 @TimeStamp   = getdate(),  
 @File_Write_Parm_Name = 'WriteDebugMessagesToFile',  
 @File_Write   = '1',  
 @File_Write_Limit  = 7  
  
SELECT @File_Path = nullif(ltrim(rtrim(Value)),'')  
FROM [dbo].Site_Parameters  
WHERE Parm_Id = 101  
  
IF @File_Path IS NULL  
     SELECT @File_Path = 'C:\'  
  
SELECT @File_Write_Parm_Id = Parm_Id  
FROM [dbo].Parameters  
WHERE Parm_Name = @File_Write_Parm_Name  
  
IF @File_Write_Parm_Id IS NOT NULL  
     SELECT @File_Write = ltrim(rtrim(Value))  
     FROM [dbo].Site_Parameters  
     WHERE Parm_Id = @File_Write_Parm_Id  
  
/***********************************************************************************************************************  
*                                           Write Message                                                            *  
***********************************************************************************************************************/  
IF @Stored_Procedure_Name IS NOT NULL AND @Message  IS NOT NULL  
     BEGIN  
     INSERT INTO [dbo].Local_Debug_Messages ( Stored_Procedure_Name,  
      TimeStamp,  
      Message)  
     VALUES ( @Stored_Procedure_Name,  
  @TimeStamp,  
  @Message)    
  
     IF @File_Write = '1'  
          BEGIN  
          -- Output message to file  
          INSERT INTO @FileOutput ( File_Name,  
    Field_Length,  
    Field_Value,  
    Field_CR,  
    Field_Build_Path,  
    Field_Final_Path,  
    Field_Move_Mask)  
          SELECT @File_Name,   
      255,  
      '[' + convert(char(23), TimeStamp, 121) + '] ' + convert(char(40), Stored_Procedure_Name) + Message,  
      1,  
      @File_Path_Temp,  
      @File_Path,  
      @Move_Mask  
          FROM [dbo].Local_Debug_Messages  
          WHERE TimeStamp > dateadd(d, -@File_Write_Limit, @TimeStamp)  
          ORDER BY Debug_Message_Id ASC  
  
          -- Output results  
          SELECT  Result_Set_Type,  
      File_Number,  
      File_Name,   
      Field_Number,  
      Field_Name,  
      Field_Type,  
      Field_Length,  
      Field_Precision,  
      Field_Value ,  
      Field_CR,  
      Field_Build_Path,  
      Field_Final_Path,  
      Field_Move_Mask,  
      Add_Timestamp   
          FROM @FileOutput   
          ORDER BY Field_Number ASC  
          END  
     END  
  
