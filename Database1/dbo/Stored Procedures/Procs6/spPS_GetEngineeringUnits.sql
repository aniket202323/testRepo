
CREATE PROCEDURE [dbo].[spPS_GetEngineeringUnits]
 @paramType nvarchar(200) 
,@EngUnitId Int  = Null
,@EngUnitDesc nvarchar(100)  = Null
,@EngUnitCode nvarchar(100)  = Null
,@isActive bit
,@PageNumber Int  = Null -- Current page number
,@PageSize Int  = Null -- Total records per page to display


  AS
BEGIN
  if(@paramType='SEARCH')
	   BEGIN
			 DECLARE @StartPosition INT= @PageSize * (@PageNumber - 1);
			 				
		select  eng.*,COUNT(0) OVER() totalRecords FROM engineering_unit eng
			where 
				 ((@EngUnitDesc is null) or (Eng_Unit_Desc=@EngUnitDesc))
				    And ((@EngUnitCode is null) or (Eng_Unit_Code=@EngUnitCode))
					And ((@isActive is null) or (@isActive=1 and Is_Active = 1) or (@isActive=0 and Is_Active = 0))
				order by eng.Eng_Unit_Code 
				OFFSET @StartPosition ROWS
				FETCH NEXT @PageSize ROWS ONLY;
		END
    else if(@paramType='SEARCH_BY_ID')
       BEGIN        
		   SELECT eng.*, 0 as totalRecords from Engineering_unit eng
		   where eng_unit_id=@EngUnitId
       END	
END