CREATE PROCEDURE [dbo].[spBF_GetVariablesBasedonCriteria] 
 	 @department_id 	  	  	 int = NULL,
 	 @line_id 	  	  	  	 int = NULL,
 	 @unit_id 	  	  	  	 int = NULL,
 	 @vargrp_id 	  	  	  	 int = NULL,
 	 @var_datatype 	  	  	 nvarchar(50) = NULL,
 	 @name 	  	  	  	  	 nVarChar(100) = NULL,
 	 @currentPage            int = NULL,
 	 @pageSize               int = NULL
AS 
BEGIN
 	 
 	 DECLARE @RESULTS TABLE (
 	     orderedIndex             int IDENTITY(1,1) PRIMARY KEY,
        varId                    int, 
        varDesc                  nvarchar(255),
        dataTypeDesc             nvarchar(50),
        groupDesc                nvarchar(50),
        unitDesc                 nvarchar(50),
        linkedTag                nvarchar(255),
        enggUnits                nvarchar(15),
        lineDesc                 nvarchar(50),
        deptDesc                 nvarchar(50),
        dataSourceDesc           nvarchar(50),
 	  	 sample_interval          int,
 	  	 sample_type              nvarchar(50),
 	  	 tags_out                 nvarchar(255)
     )
 	 
SET @CurrentPage = ISNULL(@CurrentPage, 1)
SET @PageSize = ISNULL(@PageSize, 5)
INSERT INTO @RESULTS (varId, varDesc, dataTypeDesc, groupDesc, unitDesc, linkedTag, enggUnits, lineDesc, deptDesc, dataSourceDesc, sample_interval, sample_type, tags_out)
SELECT 	 V.var_id, 
 	  	  	     V.Var_Desc,
 	  	  	     DT.Data_Type_Desc, 
 	  	  	     G.pug_desc, 
 	  	  	     U.pu_desc,
 	  	  	     V.Input_tag,
 	  	         V.Eng_Units,
 	  	  	     L.PL_Desc,
 	  	         D.Dept_Desc, 
 	  	         DS.DS_Desc,
 	  	  	  	 V.Sampling_Interval,
 	  	  	  	 ST.ST_Desc,
 	  	  	  	 V.Output_Tag
 	  	 FROM Departments_Base D WITH(NOLOCK)
 	  	 JOIN Prod_Lines_Base  L WITH(NOLOCK)  ON D.Dept_Id = L.Dept_Id
 	  	 JOIN prod_units       U WITH(NOLOCK)  ON L.PL_Id = U.PL_Id
 	  	 JOIN pu_groups        G WITH(NOLOCK)  ON U.PU_Id = G.PU_Id
 	  	 JOIN variables        V WITH(NOLOCK)  ON G.PUG_Id = V.PUG_Id
 	  	 LEFT JOIN Data_Type        DT WITH(NOLOCK) ON V.Data_Type_Id = DT.Data_Type_Id 
 	  	 LEFT JOIN Data_Source      DS WITH(NOLOCK) ON V.DS_Id = DS.DS_Id
 	  	 LEFT JOIN Sampling_Type    ST WITH(NOLOCK) ON V.Sampling_Type = ST.ST_Id
 	  	 WHERE D.Dept_Id = COALESCE(@department_id, D.Dept_Id)
 	  	 AND 	 L.PL_Id 	  	 = COALESCE(@line_id, L.PL_Id)
 	  	 AND U.PU_Id 	  	 = COALESCE(@unit_id, U.PU_Id)
 	  	 AND G.PUG_Id 	 = COALESCE(@vargrp_id, G.PUG_Id)
 	  	 AND V.Var_Desc LIKE CASE WHEN @name = '*' THEN '%' ELSE  '%' + @name + '%' END
 	  	 
SELECT     varId,
           varDesc,
           dataTypeDesc,
           groupDesc,
           unitDesc,
           linkedTag,
           enggUnits,
           lineDesc,
           deptDesc,
           dataSourceDesc,
 	  	    sample_interval,
 	  	    sample_type,
 	  	    tags_out,
         (SELECT COUNT(*) FROM @RESULTS) AS NbResults,
         @CurrentPage AS CurrentPage,
         @PageSize AS PageSize,
         FLOOR(CEILING(Cast((SELECT COUNT(*) FROM @RESULTS) as decimal(18,2))/ @PageSize)) as TotalPages 
FROM @RESULTS 
WHERE orderedIndex BETWEEN 1 + ((@CurrentPage - 1) * @PageSize) AND (@CurrentPage) * @PageSize
 	  	 
 	  	  	 
END
GRANT EXECUTE ON [dbo].[spBF_GetVariablesBasedonCriteria] TO [ComXClient]
SET ANSI_NULLS ON
