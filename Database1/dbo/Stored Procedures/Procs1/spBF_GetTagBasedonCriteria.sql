CREATE PROCEDURE [dbo].[spBF_GetTagBasedonCriteria] 
 	    @department_id 	  	  	 int,
       @line_id                 int,
       @unit_id                 int,
       @vargrp_id               int,
       @var_datatype            nvarchar(100),
       @name 	  	  	  	  	 nVarChar(100)
AS 
BEGIN
DECLARE @RESULTS TABLE (
 	   orderedIndex             int IDENTITY(1,1) PRIMARY KEY,
        varId                    int, 
        inputTag                 nvarchar(255),
        dataTypeDesc             nvarchar(50),
        groupDesc                nvarchar(50),
        unitDesc                 nvarchar(50),
        varDesc                  nvarchar(255),
        enggUnits                nvarchar(15),
        lineDesc                 nvarchar(50),
        deptDesc                 nvarchar(50),
        numOfVariables           int
 	  	 
     )
 	 
 	 INSERT INTO @RESULTS (varId, inputTag, dataTypeDesc, groupDesc, unitDesc, varDesc, enggUnits, lineDesc, deptDesc, numOfVariables)
 	  	 SELECT  V.var_id, 
                V.Input_tag,
                DT.Data_Type_Desc, 
                G.pug_desc, 
                U.pu_desc,
                V.Var_Desc,
 	  	  	  	 V.Eng_Units,
                L.PL_Desc,
 	  	  	  	 D.Dept_Desc,
 	  	  	  	 NoOfVariables = (SELECT COUNT(*) FROM Variables V2 WHERE V2.Input_Tag = V.Input_Tag) 
 	  	 FROM Departments_Base D WITH(NOLOCK)
 	  	 JOIN Prod_Lines_Base  L WITH(NOLOCK)  ON D.Dept_Id = L.Dept_Id
 	  	 JOIN prod_units       U WITH(NOLOCK)  ON L.PL_Id = U.PL_Id
 	  	 JOIN pu_groups        G WITH(NOLOCK)  ON U.PU_Id = G.PU_Id
 	  	 JOIN variables        V WITH(NOLOCK)  ON G.PUG_Id = V.PUG_Id
 	  	 LEFT JOIN Data_Type        DT WITH(NOLOCK) ON V.Data_Type_Id = DT.Data_Type_Id 
 	  	 WHERE D.Dept_Id = COALESCE(@department_id, D.Dept_Id)
 	  	 AND L.PL_Id 	  	 = COALESCE(@line_id, L.PL_Id)
 	  	 AND U.PU_Id 	  	 = COALESCE(@unit_id, U.PU_Id)
 	  	 AND G.PUG_Id 	 = COALESCE(@vargrp_id, G.PUG_Id)
 	  	 AND V.Input_tag LIKE CASE WHEN @name = '*' THEN '%' ELSE  '%' + @name + '%' END
 	  	 AND V.Input_tag IS NOT NULL --GROUP BY V.Input_tag
 	  	 ; WITH CTE AS (
        SELECT *
        , ROW_NUMBER() OVER (PARTITION BY [inputTag],unitDesc  ORDER BY [inputTag],unitDesc ) AS Picker
        FROM @RESULTS
        )
 	  	  
        DELETE CTE 
        WHERE Picker > 1
SELECT varId,
       inputTag,
 	    dataTypeDesc,
 	    groupDesc,
 	    unitDesc,
 	    varDesc,
 	    enggUnits,
 	    lineDesc,
 	    deptDesc,
 	    numOfVariables 
FROM @RESULTS 
END
