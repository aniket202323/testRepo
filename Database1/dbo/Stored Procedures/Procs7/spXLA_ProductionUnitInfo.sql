-- ECR ##29826: mt/10-26-2005: spXLA_ProductionUnitInfo retrieve production unit information 
-- Must handle duplicate PU_Desc since GBDB doesn't enforced unique PU_Desc across the entire system. PU_Desc is only unique within PL_Id
-- Production Unit Attributes function (via this stored procedure) is NOT responsible for group security, the production unit search function is. 
-- Once users obtain PU_Id, they can query production unit attributes.
--
CREATE PROCEDURE dbo.spXLA_ProductionUnitInfo
 	   @PU_Id        Int
 	 , @PU_Desc      Varchar(50)
AS
DECLARE @UnitFetchCount Int
If @PU_Desc IS NULL AND @PU_Id IS NULL
  BEGIN
    SELECT [ReturnStatus] = -105 	  	 --input production unit NOT SPECIFIED
    RETURN
  END
Else If @PU_Desc Is NULL --we have @PU_Id
  BEGIN
    SELECT @PU_Desc = pu.PU_Desc FROM Prod_Units pu WHERE pu.PU_Id = @PU_Id
    SELECT @UnitFetchCount = @@ROWCOUNT
    If @UnitFetchCount = 0
      BEGIN
        SELECT [ReturnStatus] = -100 	 --specified production unit NOT FOUND
        RETURN
      END
    --EndIf:Count=0   
  END
Else --@PU_Desc NOT null, use it
  BEGIN
    SELECT @PU_Id = pu.PU_Id FROM Prod_Units pu WHERE pu.PU_Desc = @PU_Desc
    SELECT @UnitFetchCount = @@ROWCOUNT
    If @UnitFetchCount <> 1
      BEGIN
        If @UnitFetchCount = 0
          SELECT [ReturnStatus] = -100 	 --specified production unit NOT FOUND
        Else --too many PU_Desc
          SELECT [ReturnStatus] = -103 	 --DUPLICATE FOUND in PU_Desc
        --EndIf:Count
        RETURN
      END
    --EndIf:Count<>1
  END
--EndIf:Both @PU_Id and @PU_Desc null
--
-- Now get Production Unit Attributes
--
SELECT pu.PU_Id 
     , pu.PU_Desc
     , pu.Comment_Id
     , pu.Extended_Info
     , pu.Tag
     , pu.User_Defined1
     , pu.User_Defined2
     , pu.User_Defined3
     , pu.External_Link
     , [Parent_Child_Relation] = Case When pu.Master_Unit Is NULL Then 'Parent' Else 'Child' End
     , [PL_Desc]               = pl.PL_Desc
     , [Event_Configured]      = Case When pu.Production_Event_Association Is NULL Then 'No' Else 'Yes' End
     , [Downtime_Configured]   = Case When pu.Timed_Event_Association Is NULL Then 'No' Else 'Yes' End
     , [Waste_Configured]      = Case When pu.Waste_Event_Association Is NULL Then 'No' Else 'Yes' End
     , [Delete_Child_Events]   = Case When pu.Delete_Child_Events = 0 Then 'No' Else 'Yes' End
     , [Start_Time_Active]     = Case When pu.Uses_Start_Time Is NULL Then 'No' Else 'Yes' End
        --
        -- Prod_Units.Production_Rate_TimeUnits should get its values from another table in the Database 
        -- However, admin module is currently feeding this column with values hard coded in Applications.  
        -- This is BAD design since all stored procedures must be aware of this fact.
        --
     , [Production_Rate_TimeUnits] = Case When pu.Production_Rate_TimeUnits = 0 Then 'Hour'
                                          When pu.Production_Rate_TimeUnits = 1 Then 'Minute'
                                          When pu.Production_Rate_TimeUnits = 2 Then 'Second'
                                          When pu.Production_Rate_TimeUnits = 3 Then 'Day'
                                          Else 'Unknown'
                                     End
        --
        -- Another bad database design: There should be another table to store "Production Type"
        -- Must hard code the description to get around the lack of "Production Type" table.
        --
     , [Production_Type]     = Case When pu.Production_Type = 0 Then 'Event Dimension Based' Else 'Variable Based' End
     , [Unit_Type] = ut.UT_Desc
     , [Efficiency_Percent_Specification] = s1.Spec_Desc
     , [Downtime_Percent_Specification]   = s2.Spec_Desc
     , [Waste_Percent_Specification]      = s3.Spec_Desc
     , [Production_Rate_Specification]    = s4.Spec_Desc
     , [Efficiency_Variable]              = v1.Var_Desc
     , [Production_Variable]              = v2.Var_Desc
     , [Downtime_External_Category]       = erc1.ERC_Desc
     , [Downtime_Scheduled_Category]      = erc2.ERC_Desc
     , [Performance_Downtime_Category]    = erc3.ERC_Desc
     , [Default_Path]                     = productExecPath.Path_Desc
FROM Prod_Units pu 
JOIN Prod_Lines pl          ON pl.PL_Id        = pu.PL_Id
LEFT JOIN Unit_Types ut     ON ut.Unit_Type_Id = pu.Unit_Type_Id
LEFT JOIN Specifications s1 ON s1.Spec_Id      = pu.Efficiency_Percent_Specification
LEFT JOIN Specifications s2 ON s2.Spec_Id      = pu.Downtime_Percent_Specification
LEFT JOIN Specifications s3 ON s3.Spec_Id      = pu.Waste_Percent_Specification
LEFT JOIN Specifications s4 ON s4.Spec_Id      = pu.Production_Rate_Specification
LEFT JOIN Variables v1      ON v1.Var_Id       = pu.Efficiency_Variable
LEFT JOIN Variables v2      ON v2.Var_Id       = pu.Production_Variable
LEFT JOIN Event_Reason_Catagories erc1  ON erc1.ERC_Id             = pu.Downtime_External_Category
LEFT JOIN Event_Reason_Catagories erc2  ON erc2.ERC_Id             = pu.Downtime_Scheduled_Category
LEFT JOIN Event_Reason_Catagories erc3  ON erc3.ERC_Id             = pu.Performance_Downtime_Category
LEFT JOIN PrdExec_Paths productExecPath ON productExecPath.Path_Id = pu.Default_Path_Id
WHERE pu.PU_Id = @PU_Id
