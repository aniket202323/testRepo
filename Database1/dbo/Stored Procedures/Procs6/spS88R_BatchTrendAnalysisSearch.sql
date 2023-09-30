CREATE procedure [dbo].[spS88R_BatchTrendAnalysisSearch]
--declare 
@UserId int,
@SearchString nVarChar(255),
@InTimeZone nVarChar(200)=NULL
AS
/***************************
-- For Testing
--***************************
Select @SearchString = NULL
--***************************/
If @SearchString Is Null
  select Id = sa.Analysis_Id, sa.Name, sa.Description, 
 	  	  SavedBy = u.Username, 
 	  	  SavedOn = [dbo].[fnServer_CmnConvertFromDbTime] (sa.Saved_On,@InTimeZone)--Sarla   
    from Batch_Analysis sa
    left outer join users u on u.user_id = sa.saved_by
    left outer join user_security us on us.group_id = sa.group_id 
    Where sa.Source = 'ASP_EA' and
        ((sa.group_id is null) or (us.access_level >= 1)) 
    Order By sa.Name
Else
  select Id = sa.Analysis_Id, sa.Name, sa.Description, 
 	  	  SavedBy = u.Username, 
 	  	  SavedOn = [dbo].[fnServer_CmnConvertFromDbTime] (sa.Saved_On,@InTimeZone)--Sarla   
    from Batch_Analysis sa
    left outer join users u on u.user_id = sa.saved_by 
    left outer join user_security us on us.group_id = sa.group_id 
    Where sa.Source = 'ASP_EA' and 
        ((sa.Name like '%' + @SearchString + '%') or (sa.Description like '%' + @SearchString + '%'))  and
        ((sa.group_id is null) or (us.access_level >= 1)) 
    Order By sa.Name
