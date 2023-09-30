CREATE procedure [dbo].[spS88R_BatchReferenceSearch]
  @UserId INT,
  @SearchString nvarchar(255),
  @Source nvarchar(20),
  @InTimeZone nvarchar(200)=NULL
AS
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
--**********************************************
/***************************
-- For Testing
--***************************
exec spS88R_BatchReferenceSearch 1, NULL, RefBatches
--***************************/
SELECT [Id] = r.Event_Id,
       BatchName = r.[Name],
       Product = case when e.applied_product is null Then p1.Prod_Code Else p2.Prod_Code End,
       Status = psd.ProdStatus_Desc,
       r.[Description],
       UnitName = pu.pu_desc,
       Comment =  dbo.fnTranslate(@LangId, 35013, 'Saved By {0} At {1}'),
       Comment_Parameter = coalesce(u.Username, ''),
       Comment_Parameter2 = [dbo].[fnServer_CmnConvertFromDbTime] (Saved_On,@InTimeZone)--Sarla 
  FROM Batch_Reference_List r
  LEFT OUTER JOIN Users u on u.[user_id] = r.saved_by 
  LEFT OUTER JOIN User_Security us on us.Group_id = r.group_id 
  JOIN Events e ON e.Event_Id = r.Event_Id
  JOIN Prod_Units pu on pu.pu_id = e.pu_id
  JOIN Production_Status psd on psd.ProdStatus_Id = e.Event_Status
  JOIN Production_Starts ps ON ps.pu_id = e.pu_id and ps.start_time <= e.timestamp and ((ps.end_time > e.timestamp) or (ps.end_time is null))
  JOIN Products p1 on p1.Prod_id = ps.prod_id
  Left Outer Join Products p2 on p2.Prod_id = e.Applied_Product
  WHERE (r.Source = @Source Or @Source Is Null)
  AND ((r.[Name] LIKE '%' + @SearchString + '%' OR @SearchString IS NULL)
      or (r.[Description] like '%' + @SearchString + '%' AND @SearchString IS NOT NULL))
  AND ((r.group_id is null) or (us.access_level >= 1)) 
       Order By r.[Name]
