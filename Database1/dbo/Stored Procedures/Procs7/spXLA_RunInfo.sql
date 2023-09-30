-- ECR #25128: mt/3-9-2003
-- spXLA_RunInfo is modified from spXLARunInfo_New. Changes include:
-- (a) Accept Production Unit either as PU_Id OR PU_Desc
-- (b) Report Error without attemp to retrieve information If PU_Desc input has duplicate name in Database
--     ( we wouldn't know which Production Unit user really want. User will have to eliminate duplicate PU_Desc or send PU_Id instead )
--
CREATE PROCEDURE dbo.spXLA_RunInfo 
 	   @Start_Time  	  	 DateTime
 	 , @End_Time  	  	 DateTime
 	 , @Pu_Id  	  	 Integer
    , @Pu_Desc              Varchar(50)
 	 , @Prod_Id  	  	 Integer
 	 , @Group_Id  	  	 Integer
 	 , @Prop_Id  	  	 Integer
 	 , @Char_Id  	  	 Integer
 	 , @NeedProductCode 	 TinyInt 	 --0 Dont need product code; 1 want product code
 	 , @TimeSort  	  	 SmallInt 
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
DECLARE @queryType 	  	  	 TinyInt
DECLARE @SingleProductNOEndAscend 	 TinyInt -- 1
DECLARE @SingleProductNOEndDescend 	 TinyInt -- 2
DECLARE @SingleProductYesEndAscend 	 TinyInt -- 3
DECLARE @SingleProductYesEndDescend 	 TinyInt -- 4
DECLARE @GroupNOEndAscend 	  	 TinyInt -- 5
DECLARE @GroupNOEndDescend 	  	 TinyInt -- 6
DECLARE @GroupYesEndAscend 	  	 TinyInt -- 7
DECLARE @GroupYesEndDescend 	  	 TinyInt -- 8
DECLARE @CharacteristicNOEndAscend 	 TinyInt -- 9 
DECLARE @CharacteristicNOEndDescend 	 TinyInt -- 10
DECLARE @CharacteristicYesEndAscend 	 TinyInt -- 11
DECLARE @CharacteristicYesEndDescend 	 TinyInt -- 12
DECLARE @GroupAndPropertyNOEndAscend 	 TinyInt -- 13 
DECLARE @GroupAndPropertyNOEndDescend 	 TinyInt -- 14
DECLARE @GroupAndPropertyYesEndAscend 	 TinyInt -- 15 
DECLARE @GroupAndPropertyYesEndDescend 	 TinyInt -- 16
DECLARE @NOProductNOEndAscend 	  	 TinyInt -- 17 
DECLARE @NOProductNOEndDescend 	  	 TinyInt -- 18
DECLARE @NOProductYesEndAscend 	  	 TinyInt -- 19 
DECLARE @NOProductYesEndDescend 	  	 TinyInt -- 20
 	 --Needed for internal use
DECLARE @CountOf_PU_Desc                Integer
SELECT @Start_Time = @Start_Time at time zone @InTimeZone at time zone @DBTz 
SELECT @End_Time = @End_Time at time zone @InTimeZone at time zone @DBTz 
If @PU_Id Is NULL AND @PU_Desc Is NULL
  BEGIN
    SELECT [ReturnStatus] = -105 	 --NO product unit SPECIFIED
    RETURN
  END
Else If @PU_Desc Is NULL  --we'll use @PU_Id
  BEGIN
    SELECT @PU_Desc = PU_Desc FROM Prod_Units WHERE PU_Id = @PU_Id
    SELECT @CountOf_PU_Desc = @@ROWCOUNT
    If @CountOf_PU_Desc = 0
      BEGIN
        SELECT [ReturnStatus] = -100 	 --Specified Production Unit NOT FOUND
        RETURN
      END
    --EndIf
  END
Else --@PU_Desc NOT NULL
  BEGIN
    SELECT @PU_Id = PU_Id FROM Prod_Units WHERE PU_Desc = @PU_Desc
    SELECT @CountOf_PU_Desc = @@ROWCOUNT
    --Handle Error, If any
    If @CountOf_PU_Desc <> 1
      BEGIN
        If @CountOf_PU_Desc = 0
          SELECT [ReturnStatus] = -100 	 --Specified Production Unit NOT FOUND
        Else --more than one PU_Desc found
          SELECT [ReturnStatus] = -103   --DUPLICATE FOUND for production Unit
      --EndIf
        RETURN
      END
    --EndIf Error 
  END
--EndIf @PU_Id AND @PU_Desc NULL
 	 --Define Query Types
SELECT @SingleProductNOEndAscend  	 = 1
SELECT @SingleProductNOEndDescend  	 = 2
SELECT @SingleProductYesEndAscend  	 = 3
SELECT @SingleProductYesEndDescend  	 = 4
SELECT @GroupNOEndAscend  	  	 = 5
SELECT @GroupNOEndDescend  	  	 = 6
SELECT @GroupYesEndAscend  	  	 = 7
SELECT @GroupYesEndDescend  	  	 = 8
SELECT @CharacteristicNOEndAscend  	 = 9
SELECT @CharacteristicNOEndDescend 	 = 10
SELECT @CharacteristicYesEndAscend  	 = 11
SELECT @CharacteristicYesEndDescend  	 = 12
SELECT @GroupAndPropertyNOEndAscend  	 = 13
SELECT @GroupAndPropertyNOEndDescend  	 = 14
SELECT @GroupAndPropertyYesEndAscend  	 = 15
SELECT @GroupAndPropertyYesEndDescend  	 = 16
SELECT @NOProductNOEndAscend  	  	 = 17
SELECT @NOProductNOEndDescend  	  	 = 18
SELECT @NOProductYesEndAscend  	  	 = 19
SELECT @NOProductYesEndDescend  	  	 = 20
--NOTE: We DO NOT handle all possible null combinations in product parameters (@Prod_Id, @Group_Id, @Prop_Id, and @Char_Id.)
--Proficy Add-In blocks out illegal combinations, and allows only these combination:
--   Property AND Characteristic 
--   Group Only
--   Group, Propery, AND Characteristic
--   Product Only
--   No Product Information At All
If @Prod_Id Is NOT NULL 	  	  	  	  	 --Single Product
  BEGIN
    If @End_Time IS NULL
      SELECT @QueryType = Case @TimeSort When 1 Then @SingleProductNOEndAscend Else @SingleProductNOEndDescend End
    Else
      SELECT @QueryType = Case @TimeSort When 1 Then @SingleProductYesEndAscend Else @SingleProductYesEndDescend End
    --EndIf
  END  
Else If @Group_Id Is NOT NULL AND @Prop_Id is NULL 	 --Group Only
  BEGIN
    If @End_Time IS NULL
      SELECT @QueryType = Case @TimeSort When 1 Then @GroupNOEndAscend Else @GroupNOEndDescend End
    Else
      SELECT @QueryType = Case @TimeSort When 1 Then @GroupYesEndAscend Else @GroupYesEndDescend End
    --EndIf
  END  
Else If @Prop_Id Is NOT NULL AND @Group_Id is NULL 	 --Characteristic
    If @End_Time IS NULL
      SELECT @QueryType = Case @TimeSort When 1 Then @CharacteristicNOEndAscend Else @CharacteristicNOEndDescend End
    Else
      SELECT @QueryType = Case @TimeSort When 1 Then @CharacteristicYesEndAscend Else @CharacteristicYesEndDescend End
    --EndIf
Else If @Prop_Id Is NOT NULL AND @Group_Id is not NULL 	 --Group And Property
  BEGIN
    If @End_Time IS NULL
      SELECT @QueryType = Case @TimeSort When 1 Then @GroupAndPropertyNOEndAscend Else @GroupAndPropertyNOEndDescend End
    Else
      SELECT @QueryType = Case @TimeSort When 1 Then @GroupAndPropertyYesEndAscend Else @GroupAndPropertyYesEndDescend End
    --EndIf
  END  
Else 	  	  	  	  	  	  	 --No Product Information 	  	  	  	  	  	 
  BEGIN
    If @End_Time IS NULL
      SELECT @QueryType = Case @TimeSort When 1 Then @NOProductNOEndAscend Else @NOProductNOEndDescend End
    Else
      SELECT @QueryType = Case @TimeSort When 1 Then @NOProductYesEndAscend Else @NOProductYesEndDescend End
    --EndIf
  END  
--EndIf
If @NeedProductCode = 1 GOTO DO_INCLUDE_PRODUCT_CODE_SQL
 	  	  	  	  	  	 
--Deal with Original Product As Filter
--
If @QueryType = @NoProductNOEndAscend 	  	 --17 	 
  BEGIN
 	 SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id,Start_Time = Start_Time at time zone @DBTz at time zone @InTimeZone 
        FROM gb_rsum 
       WHERE pu_id = @Pu_Id AND Start_Time = @Start_Time
    ORDER BY Start_Time 	 ASC
  END
Else If @QueryType = @NoProductNOEndDescend 	 --18
  BEGIN
 	 SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id,Start_Time = Start_Time at time zone @DBTz at time zone @InTimeZone 
        FROM gb_rsum 
       WHERE pu_id = @Pu_Id AND Start_Time = @Start_Time
    ORDER BY Start_Time DESC
  END
Else If @QueryType = @NoProductYesEndAscend 	 --19
  BEGIN
 	 SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id,Start_Time = Start_Time at time zone @DBTz at time zone @InTimeZone 
        FROM gb_rsum 
       WHERE Pu_Id = @Pu_Id AND Start_Time BETWEEN @Start_Time AND @End_Time 
    ORDER BY Start_Time ASC
  END
Else If @QueryType = @NoProductYesEndDescend 	 --20
  BEGIN
 	 SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id,Start_Time = Start_Time at time zone @DBTz at time zone @InTimeZone 
        FROM gb_rsum 
       WHERE Pu_Id = @Pu_Id AND Start_Time BETWEEN @Start_Time AND @End_Time
    ORDER BY Start_Time DESC  
  END
 	  	  	  	  	  	 -- @Prod_Id Is Not NULL 	 
Else If @QueryType = @SingleProductNOEndAscend 	 --1
  BEGIN
 	 SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id,Start_Time = Start_Time at time zone @DBTz at time zone @InTimeZone 
        FROM gb_rsum 
       WHERE pu_id = @Pu_Id AND Start_Time = @Start_Time AND prod_id = @Prod_Id
    ORDER BY Start_Time ASC
  END
Else If @QueryType = @SingleProductNOEndDescend 	 --2
  BEGIN
 	 SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id,Start_Time = Start_Time at time zone @DBTz at time zone @InTimeZone 
        FROM gb_rsum 
       WHERE pu_id = @Pu_Id AND Start_Time = @Start_Time AND prod_id = @Prod_Id
    ORDER BY Start_Time DESC
  END
Else If @QueryType = @SingleProductYesEndAscend 	 --3
  BEGIN
 	 SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id,Start_Time = Start_Time at time zone @DBTz at time zone @InTimeZone 
        FROM gb_rsum 
       WHERE Pu_Id = @Pu_Id AND Start_Time BETWEEN @Start_Time AND @End_Time AND prod_id = @Prod_Id
    ORDER BY Start_Time ASC
  END
Else If @QueryType = @SingleProductYesEndDescend --4
  BEGIN
 	 SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id,Start_Time = Start_Time at time zone @DBTz at time zone @InTimeZone 
        FROM gb_rsum 
       WHERE Pu_Id = @Pu_Id AND Start_Time BETWEEN @Start_Time AND @End_Time AND prod_id = @Prod_Id
    ORDER BY Start_Time DESC
  END 	  	  	  	  	 
Else If @QueryType = @GroupNOEndAscend 	  	 --5
  BEGIN
 	 SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id,Start_Time = Start_Time at time zone @DBTz at time zone @InTimeZone 
         FROM gb_rsum 
        WHERE pu_id = @Pu_Id
          AND Start_Time = @Start_Time
          AND prod_id IN ( SELECT g.prod_id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
     ORDER BY Start_Time ASC
  END
Else If @QueryType = @GroupNOEndDescend 	  	 --6
  BEGIN
 	 SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id,Start_Time = Start_Time at time zone @DBTz at time zone @InTimeZone 
        FROM gb_rsum 
       WHERE pu_id = @Pu_Id
         AND Start_Time = @Start_Time
         AND prod_id IN ( SELECT g.prod_id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
    ORDER BY  Start_Time DESC
  END
Else If @QueryType = @GroupYesEndAscend 	  	 --7
  BEGIN
 	 SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id,Start_Time = Start_Time at time zone @DBTz at time zone @InTimeZone 
        FROM gb_rsum 
       WHERE pu_id = @Pu_Id
         AND Start_Time BETWEEN @Start_Time AND @End_Time
         AND prod_id IN ( SELECT g.prod_id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
    ORDER BY Start_Time
  END
Else If @QueryType = @GroupYesEndDescend 	 --8
  BEGIN
 	 SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id,Start_Time = Start_Time at time zone @DBTz at time zone @InTimeZone 
        FROM gb_rsum 
       WHERE pu_id = @Pu_Id
         AND Start_Time BETWEEN @Start_Time AND @End_Time
         AND prod_id IN ( SELECT g.prod_id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
    ORDER BY Start_Time DESC
  END
Else If @QueryType = @CharacteristicNOEndAscend 	 --9
  BEGIN
 	 SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id,Start_Time = Start_Time at time zone @DBTz at time zone @InTimeZone 
        FROM gb_rsum 
       WHERE pu_id = @Pu_Id
         AND Start_Time = @Start_Time
         AND prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
    ORDER BY Start_Time ASC
  END
Else If @QueryType = @CharacteristicNOEndDescend --10
  BEGIN
 	 SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id,Start_Time = Start_Time at time zone @DBTz at time zone @InTimeZone 
        FROM gb_rsum 
       WHERE pu_id = @Pu_Id
         AND Start_Time = @Start_Time
         AND prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
    ORDER BY Start_Time DESC
  END
Else If @QueryType = @CharacteristicYesEndAscend --11
  BEGIN
 	 SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id,Start_Time = Start_Time at time zone @DBTz at time zone @InTimeZone 
        FROM gb_rsum 
       WHERE pu_id = @Pu_Id
         AND Start_Time BETWEEN @Start_Time AND @End_Time
         AND prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
    ORDER BY Start_Time
  END
Else If @QueryType = @CharacteristicYesEndDescend --12
  BEGIN
 	 SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id,Start_Time = Start_Time at time zone @DBTz at time zone @InTimeZone 
        FROM gb_rsum 
       WHERE pu_id = @Pu_Id
         AND Start_Time BETWEEN @Start_Time AND @End_Time
         AND prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
    ORDER BY Start_Time DESC
  END
Else If @QueryType = @GroupAndPropertyNOEndAscend --13
  BEGIN
 	 SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id,Start_Time = Start_Time at time zone @DBTz at time zone @InTimeZone 
        FROM gb_rsum 
       WHERE pu_id = @Pu_Id
         AND Start_Time = @Start_Time
         AND prod_id IN 
             ( SELECT c.prod_id
                 FROM pu_characteristics c 
                 JOIN product_group_data g ON c.prod_id = g.prod_id
                WHERE c.prop_id = @Prop_Id AND  c.char_id = @Char_Id AND g.product_grp_id = @Group_Id
             )
    ORDER BY Start_Time ASC
  END
Else If @QueryType = @GroupAndPropertyNOEndDescend --14
   BEGIN
 	 SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id,Start_Time = Start_Time at time zone @DBTz at time zone @InTimeZone 
        FROM gb_rsum 
       WHERE pu_id = @Pu_Id
         AND Start_Time = @Start_Time
         AND prod_id IN 
             ( SELECT C.prod_id
                 FROM pu_characteristics C 
                 JOIN product_group_data G ON C.prod_id = G.prod_id
                WHERE C.prop_id = @Prop_Id AND C.char_id = @Char_Id AND G.product_grp_id = @Group_Id
             )
    ORDER BY Start_Time DESC
  END
Else If @QueryType = @GroupAndPropertyYesEndAscend --15
  BEGIN
 	 SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id,Start_Time = Start_Time at time zone @DBTz at time zone @InTimeZone 
        FROM gb_rsum 
       WHERE pu_id = @Pu_Id
         AND (Start_Time BETWEEN @Start_Time AND @End_Time) 
         AND prod_id IN 
             ( SELECT C.prod_id
                 FROM pu_characteristics C 
                 JOIN product_group_data G ON C.prod_id = G.prod_id
                WHERE C.prop_id = @Prop_Id AND C.char_id = @Char_Id AND G.product_grp_id = @Group_Id
             )
    ORDER BY Start_Time ASC
  END
Else If @QueryType = @GroupAndPropertyYesEndDescend --16
  BEGIN
 	 SELECT  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id,Start_Time = Start_Time at time zone @DBTz at time zone @InTimeZone 
        FROM gb_rsum 
       WHERE pu_id = @Pu_Id
         AND Start_Time BETWEEN @Start_Time AND @End_Time
         AND prod_id IN 
             ( SELECT C.prod_id
                 FROM pu_characteristics C 
                 JOIN product_group_data G ON C.prod_id = G.prod_id
                WHERE C.prop_id = @Prop_Id AND C.char_id = @Char_Id AND G.product_grp_id = @Group_Id
             )
    ORDER BY Start_Time DESC
  END
--EndIf @QueryType ...
GOTO EXIT_PROCEDURE
-- ******************************************************************************
-- ******************************************************************************
-- ******************************************************************************
DO_INCLUDE_PRODUCT_CODE_SQL:
  If @QueryType = @NoProductNOEndAscend   --17
    BEGIN
 	 SELECT   p.Prod_Code,rs.RSum_Id,rs.Comment_Id,rs.Conf_Index,rs.Duration,
 	  	  	 End_Time = rs.End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 rs.In_Limit,rs.In_Warning,rs.Prod_Id,rs.PU_Id,
 	  	  	 Start_Time = rs.Start_Time at time zone @DBTz at time zone @InTimeZone 
          FROM gb_rsum rs
          JOIN Products p ON p.Prod_Id = rs.Prod_Id
         WHERE rs.Pu_id = @Pu_Id AND rs.Start_Time = @Start_Time
      ORDER BY rs.Start_Time ASC
    END
  Else If @QueryType = @NoProductNOEndDescend  --18
    BEGIN
 	 SELECT   p.Prod_Code,rs.RSum_Id,rs.Comment_Id,rs.Conf_Index,rs.Duration,
 	  	  	 End_Time = rs.End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 rs.In_Limit,rs.In_Warning,rs.Prod_Id,rs.PU_Id,
 	  	  	 Start_Time = rs.Start_Time at time zone @DBTz at time zone @InTimeZone 
          FROM gb_rsum rs
          JOIN Products p ON p.Prod_Id = rs.Prod_Id
         WHERE rs.Pu_id = @Pu_Id AND rs.Start_Time = @Start_Time
      ORDER BY rs.Start_Time DESC
    END
  Else If @QueryType = @NoProductYesEndAscend --19
    BEGIN
 	 SELECT   p.Prod_Code,rs.RSum_Id,rs.Comment_Id,rs.Conf_Index,rs.Duration,
 	  	  	 End_Time = rs.End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 rs.In_Limit,rs.In_Warning,rs.Prod_Id,rs.PU_Id,
 	  	  	 Start_Time = rs.Start_Time at time zone @DBTz at time zone @InTimeZone 
          FROM gb_rsum rs
          JOIN Products p ON p.Prod_Id = rs.Prod_Id
         WHERE rs.Pu_Id = @Pu_Id AND rs.Start_Time BETWEEN @Start_Time AND @End_Time
      ORDER BY rs.Start_Time ASC
    END
  Else If @QueryType = @NoProductYesEndDescend --20
    BEGIN
 	 SELECT   p.Prod_Code,rs.RSum_Id,rs.Comment_Id,rs.Conf_Index,rs.Duration,
 	  	  	 End_Time = rs.End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 rs.In_Limit,rs.In_Warning,rs.Prod_Id,rs.PU_Id,
 	  	  	 Start_Time = rs.Start_Time at time zone @DBTz at time zone @InTimeZone 
          FROM gb_rsum rs
          JOIN Products p ON p.Prod_Id = rs.Prod_Id
         WHERE rs.Pu_Id = @Pu_Id AND rs.Start_Time BETWEEN @Start_Time AND @End_Time
      ORDER BY rs.Start_Time DESC
    END
  Else If @QueryType = @SingleProductNOEndAscend  --1
    BEGIN
 	 SELECT   p.Prod_Code,rs.RSum_Id,rs.Comment_Id,rs.Conf_Index,rs.Duration,
 	  	  	 End_Time = rs.End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 rs.In_Limit,rs.In_Warning,rs.Prod_Id,rs.PU_Id,
 	  	  	 Start_Time = rs.Start_Time at time zone @DBTz at time zone @InTimeZone 
          FROM gb_rsum rs
          JOIN Products p ON p.Prod_Id = rs.Prod_Id
         WHERE rs.Pu_id = @Pu_Id AND rs.Start_Time = @Start_Time AND rs.Prod_id = @Prod_Id
      ORDER BY rs.Start_Time ASC
    END
  Else If @QueryType = @SingleProductNOEndDescend --2
    BEGIN
 	 SELECT   p.Prod_Code,rs.RSum_Id,rs.Comment_Id,rs.Conf_Index,rs.Duration,
 	  	  	 End_Time = rs.End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 rs.In_Limit,rs.In_Warning,rs.Prod_Id,rs.PU_Id,
 	  	  	 Start_Time = rs.Start_Time at time zone @DBTz at time zone @InTimeZone 
          FROM gb_rsum rs
          JOIN Products p ON p.Prod_Id = rs.Prod_Id
         WHERE rs.Pu_id = @Pu_Id AND rs.Start_Time = @Start_Time AND rs.Prod_id = @Prod_Id
      ORDER BY rs.Start_Time DESC
    END
  Else If @QueryType = @SingleProductYesEndAscend --3
    BEGIN
 	 SELECT   p.Prod_Code,rs.RSum_Id,rs.Comment_Id,rs.Conf_Index,rs.Duration,
 	  	  	 End_Time = rs.End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 rs.In_Limit,rs.In_Warning,rs.Prod_Id,rs.PU_Id,
 	  	  	 Start_Time = rs.Start_Time at time zone @DBTz at time zone @InTimeZone 
          FROM gb_rsum rs
          JOIN Products p ON p.Prod_Id = rs.Prod_Id
         WHERE rs.Pu_Id = @Pu_Id AND rs.Start_Time BETWEEN @Start_Time AND @End_Time AND rs.Prod_id = @Prod_Id
      ORDER BY rs.Start_Time ASC
    END
  Else If @QueryType = @SingleProductYesEndDescend --4
    BEGIN
 	 SELECT   p.Prod_Code,rs.RSum_Id,rs.Comment_Id,rs.Conf_Index,rs.Duration,
 	  	  	 End_Time = rs.End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 rs.In_Limit,rs.In_Warning,rs.Prod_Id,rs.PU_Id,
 	  	  	 Start_Time = rs.Start_Time at time zone @DBTz at time zone @InTimeZone 
          FROM gb_rsum rs
          JOIN Products p ON p.Prod_Id = rs.Prod_Id
         WHERE rs.Pu_Id = @Pu_Id AND rs.Start_Time BETWEEN @Start_Time AND @End_Time AND rs.Prod_id = @Prod_Id
      ORDER BY rs.Start_Time DESC
    END
  Else If @QueryType = @GroupNOEndAscend    --5
    BEGIN
 	 SELECT   p.Prod_Code,rs.RSum_Id,rs.Comment_Id,rs.Conf_Index,rs.Duration,
 	  	  	 End_Time = rs.End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 rs.In_Limit,rs.In_Warning,rs.Prod_Id,rs.PU_Id,
 	  	  	 Start_Time = rs.Start_Time at time zone @DBTz at time zone @InTimeZone 
           FROM gb_rsum rs
          JOIN Products p ON p.Prod_Id = rs.Prod_Id
          WHERE pu_id = @Pu_Id
            AND rs.Start_Time = @Start_Time
            AND rs.Prod_id IN ( SELECT g.Prod_Id FROM product_group_data g WHERE g.Product_Grp_Id = @Group_Id )
       ORDER BY rs.Start_Time ASC
    END
  Else If @QueryType = @GroupNOEndDescend   --6
    BEGIN
 	 SELECT   p.Prod_Code,rs.RSum_Id,rs.Comment_Id,rs.Conf_Index,rs.Duration,
 	  	  	 End_Time = rs.End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 rs.In_Limit,rs.In_Warning,rs.Prod_Id,rs.PU_Id,
 	  	  	 Start_Time = rs.Start_Time at time zone @DBTz at time zone @InTimeZone 
          FROM gb_rsum rs
          JOIN Products p ON p.Prod_Id = rs.Prod_Id
         WHERE rs.Pu_id = @Pu_Id
           AND rs.Start_Time = @Start_Time
           AND rs.Prod_id IN ( SELECT g.prod_id FROM  product_group_data g WHERE g.product_grp_id = @Group_Id )
      ORDER BY rs.Start_Time DESC
    END
  Else If @QueryType = @GroupYesEndAscend   --7
    BEGIN
 	 SELECT   p.Prod_Code,rs.RSum_Id,rs.Comment_Id,rs.Conf_Index,rs.Duration,
 	  	  	 End_Time = rs.End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 rs.In_Limit,rs.In_Warning,rs.Prod_Id,rs.PU_Id,
 	  	  	 Start_Time = rs.Start_Time at time zone @DBTz at time zone @InTimeZone 
          FROM gb_rsum rs
          JOIN Products p ON p.Prod_Id = rs.Prod_Id
         WHERE rs.pu_id = @Pu_Id
           AND rs.Start_Time BETWEEN @Start_Time AND @End_Time
           AND rs.prod_id IN ( SELECT g.prod_id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
      ORDER BY rs.Start_Time
    END
  Else If @QueryType = @GroupYesEndDescend  --8
    BEGIN
 	 SELECT   p.Prod_Code,rs.RSum_Id,rs.Comment_Id,rs.Conf_Index,rs.Duration,
 	  	  	 End_Time = rs.End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 rs.In_Limit,rs.In_Warning,rs.Prod_Id,rs.PU_Id,
 	  	  	 Start_Time = rs.Start_Time at time zone @DBTz at time zone @InTimeZone 
          FROM gb_rsum rs
          JOIN Products p ON p.Prod_Id = rs.Prod_Id
         WHERE rs.pu_id = @Pu_Id
           AND rs.Start_Time BETWEEN @Start_Time AND @End_Time
           AND rs.prod_id IN ( SELECT g.prod_id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
      ORDER BY rs.Start_Time DESC
    END
  Else If @QueryType = @CharacteristicNOEndAscend --9
    BEGIN
 	 SELECT   p.Prod_Code,rs.RSum_Id,rs.Comment_Id,rs.Conf_Index,rs.Duration,
 	  	  	 End_Time = rs.End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 rs.In_Limit,rs.In_Warning,rs.Prod_Id,rs.PU_Id,
 	  	  	 Start_Time = rs.Start_Time at time zone @DBTz at time zone @InTimeZone 
          FROM gb_rsum rs
          JOIN Products p ON p.Prod_Id = rs.Prod_Id
         WHERE rs.pu_id = @Pu_Id
           AND rs.Start_Time = @Start_Time
           AND rs.prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
      ORDER BY rs.Start_Time ASC
    END
  Else If @QueryType = @CharacteristicNOEndDescend --10
    BEGIN
 	 SELECT   p.Prod_Code,rs.RSum_Id,rs.Comment_Id,rs.Conf_Index,rs.Duration,
 	  	  	 End_Time = rs.End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 rs.In_Limit,rs.In_Warning,rs.Prod_Id,rs.PU_Id,
 	  	  	 Start_Time = rs.Start_Time at time zone @DBTz at time zone @InTimeZone 
          FROM gb_rsum rs
          JOIN Products p ON p.Prod_Id = rs.Prod_Id
         WHERE rs.pu_id = @Pu_Id
           AND rs.Start_Time = @Start_Time
           AND rs.prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
      ORDER BY rs.Start_Time DESC
    END
  Else If @QueryType = @CharacteristicYesEndAscend --11
    BEGIN
 	 SELECT   p.Prod_Code,rs.RSum_Id,rs.Comment_Id,rs.Conf_Index,rs.Duration,
 	  	  	 End_Time = rs.End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 rs.In_Limit,rs.In_Warning,rs.Prod_Id,rs.PU_Id,
 	  	  	 Start_Time = rs.Start_Time at time zone @DBTz at time zone @InTimeZone 
          FROM gb_rsum rs
          JOIN Products p ON p.Prod_Id = rs.Prod_Id
         WHERE rs.pu_id = @Pu_Id
           AND rs.Start_Time BETWEEN @Start_Time AND @End_Time
           AND rs.prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
      ORDER BY rs.Start_Time ASC
    END
  Else If @QueryType = @CharacteristicYesEndDescend --12
    BEGIN
 	 SELECT   p.Prod_Code,rs.RSum_Id,rs.Comment_Id,rs.Conf_Index,rs.Duration,
 	  	  	 End_Time = rs.End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 rs.In_Limit,rs.In_Warning,rs.Prod_Id,rs.PU_Id,
 	  	  	 Start_Time = rs.Start_Time at time zone @DBTz at time zone @InTimeZone 
          FROM gb_rsum rs
          JOIN Products p ON p.Prod_Id = rs.Prod_Id
         WHERE rs.pu_id = @Pu_Id
           AND rs.Start_Time BETWEEN @Start_Time AND @End_Time
           AND rs.prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
      ORDER BY rs.Start_Time DESC
    END
  Else If @QueryType = @GroupAndPropertyNOEndAscend --13
    BEGIN
 	 SELECT   p.Prod_Code,rs.RSum_Id,rs.Comment_Id,rs.Conf_Index,rs.Duration,
 	  	  	 End_Time = rs.End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 rs.In_Limit,rs.In_Warning,rs.Prod_Id,rs.PU_Id,
 	  	  	 Start_Time = rs.Start_Time at time zone @DBTz at time zone @InTimeZone 
          FROM gb_rsum rs
          JOIN Products p ON p.Prod_Id = rs.Prod_Id
         WHERE rs.pu_id = @Pu_Id
           AND rs.Start_Time = @Start_Time
           AND rs.prod_id IN
               ( SELECT c.prod_id
                   FROM pu_characteristics c
                   JOIN product_group_data g ON c.prod_id = g.prod_id
                  WHERE c.prop_id = @Prop_Id AND  c.char_id = @Char_Id AND g.product_grp_id = @Group_Id
               )
      ORDER BY rs.Start_Time ASC
    END
  Else If @QueryType = @GroupAndPropertyNOEndDescend --14
     BEGIN
 	 SELECT   p.Prod_Code,rs.RSum_Id,rs.Comment_Id,rs.Conf_Index,rs.Duration,
 	  	  	 End_Time = rs.End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 rs.In_Limit,rs.In_Warning,rs.Prod_Id,rs.PU_Id,
 	  	  	 Start_Time = rs.Start_Time at time zone @DBTz at time zone @InTimeZone 
          FROM gb_rsum rs
          JOIN Products p ON p.Prod_Id = rs.Prod_Id
         WHERE rs.pu_id = @Pu_Id
           AND rs.Start_Time = @Start_Time
           AND rs.prod_id IN
               ( SELECT C.prod_id
                   FROM pu_characteristics C
                   JOIN product_group_data G ON C.prod_id = G.prod_id
                  WHERE C.prop_id = @Prop_Id AND C.char_id = @Char_Id AND G.product_grp_id = @Group_Id
               )
      ORDER BY rs.Start_Time DESC
    END
  Else If @QueryType = @GroupAndPropertyYesEndAscend --15
    BEGIN
 	 SELECT   p.Prod_Code,rs.RSum_Id,rs.Comment_Id,rs.Conf_Index,rs.Duration,
 	  	  	 End_Time = rs.End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 rs.In_Limit,rs.In_Warning,rs.Prod_Id,rs.PU_Id,
 	  	  	 Start_Time = rs.Start_Time at time zone @DBTz at time zone @InTimeZone 
          FROM gb_rsum rs
          JOIN Products p ON p.Prod_Id = rs.Prod_Id
         WHERE rs.pu_id = @Pu_Id
           AND (Start_Time BETWEEN @Start_Time AND @End_Time)
           AND rs.prod_id IN
               ( SELECT C.prod_id
                   FROM pu_characteristics C
                   JOIN product_group_data G ON C.prod_id = G.prod_id
                  WHERE C.prop_id = @Prop_Id AND C.char_id = @Char_Id AND G.product_grp_id = @Group_Id
               )
      ORDER BY rs.Start_Time ASC
    END
  Else If @QueryType = @GroupAndPropertyYesEndDescend --16
    BEGIN
 	 SELECT   p.Prod_Code,rs.RSum_Id,rs.Comment_Id,rs.Conf_Index,rs.Duration,
 	  	  	 End_Time = rs.End_Time at time zone @DBTz at time zone @InTimeZone,
 	  	  	 rs.In_Limit,rs.In_Warning,rs.Prod_Id,rs.PU_Id,
 	  	  	 Start_Time = rs.Start_Time at time zone @DBTz at time zone @InTimeZone 
          FROM gb_rsum rs
          JOIN Products p ON p.Prod_Id = rs.Prod_Id
         WHERE rs.pu_id = @Pu_Id
           AND rs.Start_Time BETWEEN @Start_Time AND @End_Time
           AND rs.prod_id IN
               ( SELECT C.prod_id
                   FROM pu_characteristics C
                   JOIN product_group_data G ON C.prod_id = G.prod_id
                  WHERE C.prop_id = @Prop_Id AND C.char_id = @Char_Id AND G.product_grp_id = @Group_Id
               )
      ORDER BY rs.Start_Time DESC
    END
  --EndIf @QueryType ...
  GoTo EXIT_PROCEDURE
-- ******************************************************************************
-- ******************************************************************************
-- ******************************************************************************
EXIT_PROCEDURE:
