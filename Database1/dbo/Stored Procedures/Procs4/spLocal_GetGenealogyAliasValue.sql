 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.4  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_GetGenealogyAliasValue  
Author:   Matthew Wells (MSI)  
Date Created:  07/12/02  
  
Description:  
=========  
Retrieves any aliased variables values based on the event components.  
  
Change Date Who What  
=========== ==== =====  
05/16/03 MKW Added Array_Id.  
11/17/03 MKW Changed temp table to table variable and removed cursor  
11/18/03 MKW Added TOP 1 to Event_Components query to only ensure 1 parent is retrieved  
*/  
  
CREATE PROCEDURE dbo.spLocal_GetGenealogyAliasValue  
@Output_Value    varchar(25) OUTPUT,  
@Child_Event_Id   int  
AS  
SET NOCOUNT ON  
/* Testing   
Select  @Child_Event_Id  = 459590  
*/  
----------------------------------------------------------------------------  
--                       Declarations                                     --  
----------------------------------------------------------------------------  
DECLARE @Child_PU_Id   int,  
 @Child_TimeStamp  datetime,  
 @Parent_Event_Id  int,  
 @Parent_PU_Id   int,  
 @Parent_TimeStamp  datetime,  
 @Child_Result   varchar(25),  
 @Parent_Array_Id  int,  
 @Child_Var_Id   int,  
 @Child_Test_Id   int,  
 @Child_Array_Id   int,  
 @Count    int,  
 @Rows    int,  
 @Row    int,  
 @User_id   int,  
 @AppVersion   varchar(30)  
  
 -- Get the Proficy database version  
 SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'   
  
-- user id for the resulset  
SELECT @User_id = User_id   
FROM [dbo].Users  
WHERE username = 'Reliability System'  
   
DECLARE @Tests TABLE ( Result_Set_Type  int DEFAULT 2,  
   Var_Id   int,  
   PU_Id   int,  
   User_Id   int,  
   Canceled  int DEFAULT 0,  
   Result   varchar(25),  
   Result_On  varchar(25),  
   Transaction_Type int DEFAULT 1,  
   Post_Update  int DEFAULT 0,  
   Second_User_Id  int Null,  
   Trans_Num    int Null,  
   Event_Id    int Null,  
   Array_Id    int Null,  
   Comment_Id   int Null)  
   
----------------------------------------------------------------------------  
--                       Get Event Information                            --  
----------------------------------------------------------------------------  
SELECT @Child_PU_Id   = PU_Id,  
 @Child_TimeStamp = TimeStamp  
FROM [dbo].Events  
WHERE Event_Id = @Child_Event_Id  
  
SELECT TOP 1 @Parent_Event_Id = Source_Event_Id  
FROM [dbo].Event_Components  
WHERE Event_Id = @Child_Event_Id  
  
SELECT @Parent_PU_Id   = PU_Id,  
 @Parent_TimeStamp = TimeStamp  
FROM [dbo].Events  
WHERE Event_Id = @Parent_Event_Id  
  
----------------------------------------------------------------------------  
--               Return results for non-array data types                  --  
----------------------------------------------------------------------------  
INSERT INTO @Tests ( Var_Id,  
   PU_Id,  
   Result,  
   Result_On,User_id)  
SELECT cv.Var_Id,  
 cv.PU_Id,  
 pt.Result,  
 convert(varchar(25), @Child_TimeStamp, 120),  
 @User_id  
FROM [dbo].Variables cv  
     INNER JOIN [dbo].Variable_Alias va ON cv.Var_Id = va.Dst_Var_Id  
     INNER JOIN [dbo].Variables pv ON pv.Var_Id = va.Src_Var_Id AND pv.PU_Id = @Parent_PU_Id  
     INNER JOIN [dbo].tests pt ON pt.Var_id = pv.Var_Id AND pt.Result_On = @Parent_TimeStamp  
     LEFT JOIN [dbo].tests ct ON ct.Var_Id = cv.Var_Id AND ct.Result_On = @Child_TimeStamp  
WHERE cv.PU_Id = @Child_PU_Id  
 AND cv.DS_Id = 7  
 AND cv.Data_Type_Id <> 6  
 AND cv.Data_Type_Id <> 7  
 AND isnull(ct.Result, '') <> isnull(pt.Result, '')  
  
SELECT @Count = @@ROWCOUNT  
  
----------------------------------------------------------------------------  
--                      Get data for array data types                     --  
----------------------------------------------------------------------------  
DECLARE @Variables TABLE (  
  RowId   int IDENTITY,  
  Var_Id    int,  
  PU_Id   int,  
  Result   varchar(25),  
  Test_Id   int,  
  Array_Id  int,  
  Parent_Array_Id  int)  
  
  
INSERT INTO @Variables (Var_Id,  
   PU_Id,  
   Result,  
   Test_Id,  
   Array_Id,  
   Parent_Array_Id)  
SELECT cv.Var_Id,      -- Var_Id  
 cv.PU_Id,      -- PU_Id  
 pt.Result,      -- Result  
 ct.Test_Id,  
 ct.Array_Id,  
 pt.Array_Id        
FROM [dbo].Variables cv  
     INNER JOIN [dbo].Variable_Alias va ON cv.Var_Id = va.Dst_Var_Id  
     INNER JOIN [dbo].Variables pv ON pv.Var_Id = va.Src_Var_Id AND pv.PU_Id = @Parent_PU_Id  
     INNER JOIN [dbo].tests pt ON pt.Var_id = pv.Var_Id AND pt.Result_On = @Parent_TimeStamp  
     LEFT JOIN [dbo].tests ct ON ct.Var_Id = cv.Var_Id AND ct.Result_On = @Child_TimeStamp  
WHERE cv.PU_Id = @Child_PU_Id  
 AND cv.DS_Id = 7  
 AND (cv.Data_Type_Id = 6 OR cv.Data_Type_Id = 7)  
 AND isnull(ct.Result, '') <> isnull(pt.Result, '')  
  
SELECT @Rows = @@ROWCOUNT,  
 @Row = 0  
  
WHILE @Row < @Rows  
     BEGIN  
     SELECT @Row = @Row + 1  
  
     SELECT @Child_Var_Id  = Var_Id,  
  @Child_PU_Id  = PU_Id,  
  @Child_Result  = Result,  
  @Child_Test_Id  = Test_Id,  
  @Child_Array_Id  = Array_Id,  
  @Parent_Array_Id = Parent_Array_Id  
     FROM @Variables  
     WHERE RowId = @Row  
  
     -- Insert the test entry with the array id if it doesn't already exist  
     IF @Child_Test_Id IS NULL  
          BEGIN  
          INSERT INTO [dbo].tests ( Var_Id,  
    Result_On,  
    Entry_On,  
    Entry_By,  
    Result,  
    Array_Id)  
          VALUES ( @Child_Var_Id,  
   @Child_TimeStamp,  
   getdate(),  
   @User_id,  
   NULL, --@Child_Result,  
   @Parent_Array_Id)  
          END  
     -- If the array id has changed then update the aliased variable with the new one  
     ELSE IF @Child_Array_Id IS NULL OR @Child_Array_Id <> @Parent_Array_Id  
          BEGIN  
          -- Update test value with new array id  
          UPDATE [dbo].tests  
          SET --Result  = @Child_Result,  
    Array_Id = @Parent_Array_Id,  
    Entry_On = getdate(),  
    Entry_By = @User_id  
          WHERE Test_Id = @Child_Test_Id  
          END  
  
     INSERT INTO @Tests ( Var_Id,  
    PU_Id,  
    Result,  
    Result_On,  
    Transaction_Type)  
     VALUES ( @Child_Var_Id,  
  @Child_PU_Id,  
  @Child_Result,  
  convert(varchar(25), @Child_TimeStamp, 120),  
  2)  
     END  
  
IF (@Count + @Rows) > 0  
     BEGIN  
  
  IF @AppVersion LIKE '4%'  
   BEGIN  
    SELECT Result_Set_Type,  
     Var_Id,  
     PU_Id,  
     User_Id,  
     Canceled,  
     Result,  
     Result_On,  
     Transaction_Type,  
     Post_Update,  
     Second_User_Id,  
     Trans_Num,  
     Event_Id,  
     Array_Id,  
     Comment_Id  
    FROM @Tests  
   END  
  ELSE  
   BEGIN  
    SELECT Result_Set_Type,  
     Var_Id,  
     PU_Id,  
     User_Id,  
     Canceled,  
     Result,  
     Result_On,  
     Transaction_Type,  
     Post_Update  
    FROM @Tests  
   END  
       
     END  
  
SELECT @Output_Value = '0'  
  
SET NOCOUNT OFF  
  
