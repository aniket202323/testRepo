 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-07  
Version  : 1.0.4  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_SendGenealogyAliasValue  
Author:   Matthew Wells (MSI)  
Date Created:  06/03/02  
  
Description:  
=========  
For the triggering variable it sends the value to any aliased variables associated with the next level up or down in the event components.  
  
Change Date Who What  
=========== ==== =====  
06/03/02 MKW Created.  
07/15/02 MKW Added send to parent events as well as child events and renamed variables to indicate as such.  
05/15/03 MKW Added Array_Id.  
10/03/03 MKW Removed Event_Type from the Variables Join as it was too expensive and causing the query to occasionally  
   take a really long time to execute.  
*/  
  
CREATE PROCEDURE dbo.spLocal_SendGenealogyAliasValue  
@Output_Value   varchar(25) OUTPUT,  
@TimeStamp  datetime,  
@Var_Id   int  
AS  
  
/* Testing   
Select  @Var_Id   = 5239, --4738, --4629,  
-- @Turnover_Event_Id =326400,  
 @Turnover_TimeStamp = '2002-06-03 15:42:57'  
*/  
SET NOCOUNT ON  
DECLARE @Value_Str   varchar(25),  
 @Value    float,  
 @CalcMgr_User_Id  int,  
 @EventMgr_User_Id  int,  
 @User_Id   int,  
 @Event_Id   int,  
 @PU_Id    int,  
 @Event_Type   int,  
 @Production_Event_Type_Id int,  
 @Array_Id   int,  
 @Transaction_Type  int,  
 @Aliased_Test_Id  int,  
 @Aliased_Var_Id   int,  
 @Aliased_Array_Id  int,  
 @Aliased_Result_On  datetime,  
 @AppVersion   varchar(30)  
   
  
 -- Get the Proficy database version  
 SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'   
  
SELECT  @Output_Value    = NULL,  
 @EventMgr_User_Id  = 6,  
 @Value_Str   = NULL,  
 @PU_Id    = NULL,  
 @Event_Id   = NULL,  
 @Event_Type   = NULL,  
 @Production_Event_Type_Id = 1,  
 @User_Id   = NULL,  
 @Array_Id   = NULL  
  
SELECT  @PU_Id  = coalesce(pu.Master_Unit, pu.PU_Id),  
 @Event_Type = Event_Type  
FROM [dbo].Variables v  
     INNER JOIN [dbo].Prod_Units pu On v.PU_Id = pu.PU_Id  
WHERE v.Var_Id = @Var_Id  
  
IF @Event_Type = @Production_Event_Type_Id  
     BEGIN  
     SELECT @Event_Id = Event_Id  
     FROM [dbo].Events  
     WHERE PU_Id = @PU_Id  
  AND TimeStamp = @TimeStamp  
  
     IF @Event_Id IS NOT NULL  
          BEGIN  
          SELECT  @Value_Str  = Result,  
   @User_Id = Entry_By,  
   @Array_Id = Array_Id  
          FROM [dbo].tests  
          WHERE Var_Id = @Var_Id  
  AND Result_On = @TimeStamp  
  
          IF @Value_Str IS NOT NULL AND @User_Id <> @EventMgr_User_Id  
               BEGIN  
               IF @Array_Id IS NULL  
                    BEGIN  
                    -- Return test results for any child event variables associated with this event's variable  
                    SELECT 2,       -- Result_Set_Type  
         v.Var_Id,      -- Var_Id  
         v.PU_Id,      -- PU_Id  
         @User_id,       -- User_Id  
         0,       -- Canceled  
         @Value_Str,      -- Result  
         convert(nvarchar(25), e.TimeStamp, 120),  -- Result_On              
         CASE WHEN t.Test_Id IS NULL THEN 1  
          ELSE 2  
          END,      -- Transaction_Type  
         0       -- Post_Update  
                    FROM [dbo].Event_Components ec  
                         INNER JOIN [dbo].Events e On ec.Event_Id = e.Event_Id  
                         INNER JOIN [dbo].Variables v On e.PU_Id = v.PU_Id --AND Event_Type = @Production_Event_Type_Id  
                         INNER JOIN [dbo].Variable_Alias va On v.Var_Id = va.Dst_Var_Id AND va.Src_Var_Id = @Var_Id  
                         LEFT JOIN [dbo].tests t On e.TimeStamp = t.Result_On AND t.Var_Id = va.Dst_Var_Id --v.Var_Id  
                    WHERE ec.Source_Event_Id = @Event_Id  
  
                    -- Return test results for any parent event variables associated with this event's variable  
                    SELECT 2,       -- Result_Set_Type  
         v.Var_Id,      -- Var_Id  
         v.PU_Id,      -- PU_Id  
         @User_id,       -- User_Id  
         0,       -- Canceled  
         @Value_Str,      -- Result  
         convert(nvarchar(25), e.TimeStamp, 120),  -- Result_On              
         CASE WHEN t.Test_Id IS NULL THEN 1  
          ELSE 2  
          END,      -- Transaction_Type  
         0       -- Post_Update  
                    FROM [dbo].Event_Components ec  
                         INNER JOIN [dbo].Events e On ec.Source_Event_Id = e.Event_Id  
                         INNER JOIN [dbo].Variables v On e.PU_Id = v.PU_Id --AND Event_Type = @Production_Event_Type_Id  
                         INNER JOIN [dbo].Variable_Alias va On v.Var_Id = va.Dst_Var_Id AND va.Src_Var_Id = @Var_Id  
                         LEFT JOIN [dbo].tests t On e.TimeStamp = t.Result_On AND t.Var_Id = va.Dst_Var_Id --v.Var_Id  
                    WHERE ec.Event_Id = @Event_Id  
                    END  
               ELSE  
                    BEGIN  
       -- user id for the resulset  
       SELECT @User_id = User_id   
       FROM [dbo].Users  
       WHERE username = 'Reliability System'  
  
                    -- Create table for result sets and aliased variable's array_id  
                    DECLARE @Variables TABLE(  
        Result_Set_Type  int DEFAULT 2,  
        Var_Id    int NULL,  
        PU_Id   int NULL,  
        User_Id   int NULL,  
        Canceled  int DEFAULT 0,  
        Result   varchar(25) NULL,  
        Result_On  datetime NULL,  
        Transaction_Type int DEFAULT 1,  
        Post_Update  int DEFAULT 0,  
        Test_Id   int NULL,  
        Array_Id  int NULL,  
        SecondUserId  int Null,  
        TransNum    int Null,  
        EventId    int Null,  
        ArrayId    int Null,  
        CommentId   int Null)  
  
                    -- Return test results for any child event variables associated with this event's variable  
                    INSERT INTO @Variables ( Var_Id,  
         PU_Id,  
         Result,  
         Result_On,  
         Transaction_Type,  
         Test_Id,  
         Array_Id,User_id)  
                    SELECT v.Var_Id,      -- Var_Id  
        v.PU_Id,      -- PU_Id  
        @Value_Str,      -- Result  
        e.TimeStamp,      -- Result_On              
        2,       -- Transaction_Type  
        t.Test_Id,  
        t.Array_Id,@User_id        
                    FROM [dbo].Event_Components ec  
                         INNER JOIN [dbo].Events e On ec.Event_Id = e.Event_Id  
                         INNER JOIN [dbo].Variables v On e.PU_Id = v.PU_Id --AND Event_Type = @Production_Event_Type_Id  
                         INNER JOIN [dbo].Variable_Alias va On v.Var_Id = va.Dst_Var_Id AND va.Src_Var_Id = @Var_Id  
                         LEFT JOIN [dbo].tests t On e.TimeStamp = t.Result_On AND t.Var_Id = va.Dst_Var_Id --v.Var_Id  
                    WHERE ec.Source_Event_Id = @Event_Id  
  
                    -- Return test results for any parent event variables associated with this event's variable  
                    INSERT INTO @Variables ( Var_Id,  
      PU_Id,  
      Result,  
      Result_On,  
      Transaction_Type,  
      Test_Id,  
      Array_Id,User_id)  
                    SELECT v.Var_Id,      -- Var_Id  
         v.PU_Id,      -- PU_Id  
         @Value_Str,      -- Result  
         e.TimeStamp,      -- Result_On              
         2,       -- Transaction_Type  
         t.Test_Id,  
         t.Array_Id,@User_id        
                    FROM [dbo].Event_Components ec  
                         INNER JOIN [dbo].Events e On ec.Source_Event_Id = e.Event_Id  
                         INNER JOIN [dbo].Variables v On e.PU_Id = v.PU_Id --AND Event_Type = @Production_Event_Type_Id  
                         INNER JOIN [dbo].Variable_Alias va On v.Var_Id = va.Dst_Var_Id AND va.Src_Var_Id = @Var_Id  
                         LEFT JOIN [dbo].tests t On e.TimeStamp = t.Result_On AND t.Var_Id = va.Dst_Var_Id --v.Var_Id  
                    WHERE ec.Event_Id = @Event_Id  
  
                    -- Loop through records and create any test entries if required  
                    DECLARE Variables CURSOR FOR  
                    SELECT Var_Id,  
         Result_On,  
         Test_Id,  
         Array_Id  
                    FROM @Variables  
                    FOR READ ONLY  
                    OPEN Variables  
                    FETCH NEXT FROM Variables INTO @Aliased_Var_Id,   
       @Aliased_Result_On,  
       @Aliased_Test_Id,  
       @Aliased_Array_Id  
  
                    WHILE @@FETCH_STATUS = 0  
                         BEGIN  
                         -- Insert the test entry with the array id if it doesn't already exist  
                         IF @Aliased_Test_Id IS NULL  
                              BEGIN  
                              INSERT INTO [dbo].tests ( Var_Id,  
              Result_On,  
              Entry_On,  
              Entry_By,  
              Result,  
              Array_Id)  
                              VALUES ( @Aliased_Var_Id,  
              @Aliased_Result_On,  
              getdate(),  
              @User_id,  
              @Value_Str,  
              @Array_Id)  
                              END  
                         -- If the array id has changed then update the aliased variable with the new one  
                         ELSE IF @Aliased_Array_Id IS NULL OR @Aliased_Array_Id <> @Array_Id  
                              BEGIN  
                              -- Update test value with new array id  
                              UPDATE [dbo].tests  
                              SET Result  = @Value_Str,  
            Array_Id = @Array_Id,  
            Entry_On = getdate(),  
            Entry_By = @User_id  
                              WHERE Test_Id = @Aliased_Test_Id  
                              END  
  
  
                         FETCH NEXT FROM Variables INTO @Aliased_Var_Id,   
                   @Aliased_Result_On,  
                   @Aliased_Test_Id,  
                   @Aliased_Array_Id  
                         END  
                    CLOSE Variables  
                    DEALLOCATE Variables  
  
       IF @AppVersion LIKE '4%'  
        BEGIN  
                      SELECT Result_Set_Type,  
           Var_Id,  
           PU_Id,  
           User_Id,  
           Canceled,  
           Result,  
           convert(nvarchar(25), Result_On, 120),  
           Transaction_Type,  
           Post_Update,   
           SecondUserId,   
           TransNum,   
           EventId,   
           ArrayId,   
           CommentId  
                      FROM @Variables  
        END  
       ELSE  
        BEGIN  
                      SELECT Result_Set_Type,  
           Var_Id,  
           PU_Id,  
           User_Id,  
           Canceled,  
           Result,  
           convert(nvarchar(25), Result_On, 120),  
           Transaction_Type,  
           Post_Update  
                      FROM @Variables  
        END  
                    SELECT Result_Set_Type,  
         Var_Id,  
         PU_Id,  
         User_Id,  
         Canceled,  
         Result,  
         convert(nvarchar(25), Result_On, 120),  
         Transaction_Type,  
         Post_Update  
                    FROM @Variables  
  
                    END  
               END  
          END  
     END  
  
  
SET NOCOUNT OFF  
  
