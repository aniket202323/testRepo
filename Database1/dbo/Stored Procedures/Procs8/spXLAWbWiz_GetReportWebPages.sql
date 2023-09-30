-- ECR #26449 (mt/9-29-2003): "Select dialogs" not getting complete list of dialogs. Misses out Negative RWP_Id
-- We now use negative ID. Only 1,2,3,4,5 are reserved IDs. Change WhereClause to RWP_Id NOT in (1,2,3,4,5) instead of 
-- Where RWP_Id > 5
--
CREATE PROCEDURE dbo.spXLAWbWiz_GetReportWebPages
 	 @RWP_Id Int = NULL
AS
If @RWP_Id Is NULL
  --{ ECR #26449 (mt/9-29-2003)
  -- BEGIN SELECT * FROM Report_WebPages WHERE RWP_Id > 5
  BEGIN SELECT * FROM Report_WebPages WHERE RWP_Id NOT IN (1, 2, 3, 4, 5)
  --}
  END
Else
  BEGIN SELECT * FROM Report_WebPages WHERE RWP_Id = @RWP_Id
  END
--EndIf
