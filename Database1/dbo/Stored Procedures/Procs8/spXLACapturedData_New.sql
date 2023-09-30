--spXLACapturedData_New is modified from spXLACapturedData_Expand. Changes are
--  (1) Internal lookup of Pu_Id and 
--  (2)
--  ()
--
CREATE PROCEDURE dbo.spXLACapturedData_New
 	   @Var_Id 	  	 Integer
 	 , @Var_Desc 	  	 Varchar(50)
 	 , @Start_Time 	  	 DateTime
 	 , @End_Time 	  	 DateTime
 	 , @Prod_Id 	  	 Integer
 	 , @Group_Id 	  	 Integer
 	 , @Prop_Id 	  	 Integer
 	 , @Char_Id 	  	 Integer
 	 , @NeedProductCode 	 TinyInt
 	 , @TimeSort 	  	 smallint 
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT @Start_Time = @Start_Time at time zone @InTimeZone at time zone @DBTz 
SELECT @End_Time = @End_Time at time zone @InTimeZone at time zone @DBTz 
DECLARE @Pu_Id  	  	  	  	 Integer
DECLARE @Data_Type_Id 	  	  	 Integer
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
--Get Variable Information first
SELECT @Data_Type_Id  	 = -1
SELECT @Pu_Id  	  	 = -1
If @Var_Desc Is NULL 
  SELECT @Pu_Id = v.Pu_Id, @Data_Type_Id = v.Data_Type_Id FROM Variables v WHERE Var_Id = @Var_Id 
Else
  SELECT @Var_Id = v.Var_Id, @Pu_Id = v.Pu_Id, @Data_Type_Id = v.Data_Type_Id FROM variables v WHERE Var_Desc = @Var_Desc
--EndIf
If @Pu_Id = -1 OR @Data_Type_Id = -1 
  RETURN 	  	 --ResultSet.Fields.Count = 0 indicates to Add-In "Variable specified not found"
--EndIf
--NOTE: We DO NOT handle all possible null combinations in product parameters (@Prod_Id, @Group_Id, @Prop_Id, and @Char_Id.)
--Proficy Add-In blocks out illegal combinations, and allows only these combination:
--   Property AND Characteristic 
--   Group Only
--   Group, Propery, AND Characteristic
--   Product Only
--   No Product Information At All
--
--Deal with Original Product As Filter
--
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
--If @Prod_Id Is NOT NULL AND @End_Time is NULL 	  	  	  	  	  	 SELECT @queryType = Case When @TimeSort = 1 then 1 Else 2 end
--Else If @Prod_Id Is NOT NULL AND @End_Time is NOT NULL 	  	  	  	  	 SELECT @queryType = Case When @TimeSort = 1 then 3 Else 4 end
--Else If @Group_Id Is NOT NULL AND @Prop_Id Is NULL AND @End_Time is NULL 	  	 SELECT @queryType = Case When @TimeSort = 1 then 5 Else 6 End
--Else If @Group_Id Is NOT NULL AND @Prop_Id Is NULL AND @End_Time is NOT NULL 	  	 SELECT @queryType = Case When @TimeSort = 1 then 7 Else 8 End
--Else If @Group_Id Is NULL AND @Prop_Id Is NOT NULL AND @End_Time is NULL 	  	 SELECT @queryType = Case When @TimeSort = 1 then 9 Else 10 End
--Else If @Group_Id Is NULL AND @Prop_Id Is NOT NULL AND @End_Time is NOT NULL 	  	 SELECT @queryType = Case When @TimeSort = 1 then 11 Else 12 End
--Else If @Group_Id Is NOT NULL AND @Prop_Id Is NOT NULL AND @End_Time is NULL 	  	 SELECT @queryType = Case When @TimeSort = 1 then 13 Else 14 End
--Else If @Group_Id Is NOT NULL AND @Prop_Id Is NOT NULL AND @End_Time is NOT NULL 	 SELECT @queryType = Case When @TimeSort = 1 then 15 Else 16 End
--Else If @End_Time is NULL 	  	  	  	  	  	  	  	 SELECT @queryType = Case When @TimeSort = 1 then 17 Else 18 End
--Else If @End_Time is NOT NULL 	  	  	  	  	  	  	  	 SELECT @queryType = Case When @TimeSort = 1 then 19 Else 20 End
If @NeedProductCode = 1 GOTO DO_INCLUDE_PRODUCT_CODE_SQL
--SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
If @QueryType = @NoProductNOEndAscend 	  	 --17
  BEGIN
      SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id 
        FROM gb_dset ds  WITH (index(dset_by_pu)) 
        LEFT OUTER JOIN gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
       WHERE ds.pu_id = @Pu_Id AND TimeStamp = @Start_Time
    ORDER BY TimeStamp ASC
  END
Else If @QueryType = @NoProductNOEndDescend 	 --18
  BEGIN
      SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id 
        FROM gb_dset ds  WITH (index(dset_by_pu)) 
        LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
       WHERE ds.pu_id = @Pu_Id AND TimeStamp = @Start_Time
    ORDER BY TimeStamp DESC
  END
Else If @QueryType = @NoProductYesEndAscend 	 --19
  BEGIN
      SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id 
        FROM gb_dset ds  WITH (index(dset_by_pu)) 
        LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
       WHERE ds.pu_id = @Pu_Id AND TimeStamp BETWEEN @Start_Time AND @End_Time
    ORDER BY TimeStamp ASC
  END
Else If @QueryType = @NoProductYesEndDescend 	 --20
  BEGIN
      SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id 
        FROM gb_dset ds  WITH (index(dset_by_pu)) 
        LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
       WHERE ds.pu_id = @Pu_Id AND TimeStamp BETWEEN @Start_Time AND @End_Time
    ORDER BY TimeStamp DESC
  END
Else If @QueryType = @SingleProductNOEndAscend 	 --1
  BEGIN
      SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id 
        FROM gb_dset ds  WITH (index(dset_by_pu)) 
        LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
       WHERE ds.pu_id = @Pu_Id AND TimeStamp = @Start_Time AND prod_id = @Prod_Id
    ORDER BY TimeStamp ASC
  END
Else If @QueryType = @SingleProductNOEndDescend 	 --2
  BEGIN
      SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id 
        FROM gb_dset ds  WITH (index(dset_by_pu)) 
        LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
       WHERE ds.pu_id = @Pu_Id AND TimeStamp = @Start_Time AND prod_id = @Prod_Id
    ORDER BY TimeStamp DESC
  END
Else If @QueryType = @SingleProductYesEndAscend 	 --3
  BEGIN
      SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id 
        FROM gb_dset ds  WITH (index(dset_by_pu)) 
       LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
       WHERE ds.pu_id = @Pu_Id AND TimeStamp BETWEEN @Start_Time AND @End_Time AND prod_id = @Prod_Id
    ORDER BY TimeStamp ASC
  END
Else If @QueryType = @SingleProductYesEndDescend 	 --4
  BEGIN
      SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id 
        FROM gb_dset ds  WITH (index(dset_by_pu)) 
        LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
       WHERE ds.pu_id = @Pu_Id AND TimeStamp BETWEEN @Start_Time AND @End_Time AND prod_id = @Prod_Id
    ORDER BY TimeStamp DESC
  END
Else If @QueryType = @GroupNOEndAscend 	  	  	 --5
  BEGIN
      SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id 
        FROM gb_dset ds  WITH (index(dset_by_pu)) 
        LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
       WHERE ds.pu_id = @Pu_Id AND 	 TimeStamp = @Start_Time
         AND prod_id in ( Select prod_id FROM product_group_data WHERE product_grp_id = @Group_Id )
    ORDER BY TimeStamp ASC
  END
Else If @QueryType = @GroupNOEndDescend 	  	  	 --6
  BEGIN
      SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id 
        FROM gb_dset ds  WITH (index(dset_by_pu)) 
        LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
       WHERE ds.pu_id = @Pu_Id AND 	 TimeStamp = @Start_Time
         AND prod_id in ( Select prod_id FROM product_group_data WHERE product_grp_id = @Group_Id )
    ORDER BY TimeStamp DESC
  END
Else If @QueryType = @GroupYesEndAscend 	  	  	 --7
  BEGIN
      SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id 
        FROM gb_dset ds  WITH (index(dset_by_pu)) 
        LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
       WHERE ds.pu_id = @Pu_Id AND TimeStamp BETWEEN @Start_Time AND @End_Time
         AND prod_id in ( SELECT prod_id FROM product_group_data WHERE product_grp_id = @Group_Id )
    ORDER BY TimeStamp ASC
  END
Else If @QueryType = @GroupYesEndDescend 	  	 --8
  BEGIN
      SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id 
        FROM gb_dset ds  WITH (index(dset_by_pu)) 
        LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
       WHERE ds.pu_id = @Pu_Id AND TimeStamp BETWEEN @Start_Time AND @End_Time
         AND prod_id in ( SELECT prod_id FROM product_group_data WHERE product_grp_id = @Group_Id )
    ORDER BY TimeStamp DESC
  END
Else If @QueryType = @CharacteristicNOEndAscend 	  	 --9
  BEGIN
      SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id 
        FROM gb_dset ds  WITH (index(dset_by_pu)) 
        LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
       WHERE ds.pu_id = @Pu_Id AND TimeStamp = @Start_Time
         AND prod_id IN ( SELECT prod_id FROM  pu_characteristics WHERE prop_id = @Prop_Id AND char_id = @Char_Id )
    ORDER BY TimeStamp ASC
  END
Else If @QueryType = @CharacteristicNOEndDescend 	 --10
  BEGIN
      SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id 
        FROM gb_dset ds  WITH (index(dset_by_pu)) 
        LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
       WHERE ds.pu_id = @Pu_Id AND TimeStamp = @Start_Time
         AND prod_id IN ( SELECT prod_id FROM  pu_characteristics WHERE prop_id = @Prop_Id AND char_id = @Char_Id )
    ORDER BY TimeStamp DESC
  END
Else If @QueryType = @CharacteristicYesEndAscend 	 --11
  BEGIN
      SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id 
        FROM gb_dset ds  WITH (index(dset_by_pu)) 
        LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
       WHERE ds.pu_id = @Pu_Id AND TimeStamp BETWEEN @Start_Time AND @End_Time
         AND prod_id IN ( SELECT  prod_id FROM pu_characteristics WHERE prop_id = @Prop_Id AND char_id = @Char_Id )
    ORDER BY TimeStamp ASC
  END
Else If @QueryType = @CharacteristicYesEndDescend 	 --12
  BEGIN
      SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id 
        FROM gb_dset ds  WITH (index(dset_by_pu)) 
        LEFT OUTER JOIN 	 gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
       WHERE ds.pu_id = @Pu_Id AND TimeStamp BETWEEN @Start_Time AND @End_Time
         AND prod_id IN ( SELECT prod_id FROM pu_characteristics WHERE prop_id = @Prop_Id AND char_id = @Char_Id )
    ORDER BY TimeStamp DESC
  END
Else If @QueryType = @GroupAndPropertyNOEndAscend 	 --13
  BEGIN
       SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id 
         FROM gb_dset ds  WITH (index(dset_by_pu)) 
         LEFT OUTER JOIN gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
        WHERE ds.pu_id = @Pu_Id AND TimeStamp = @Start_Time
          AND prod_id IN 
              ( SELECT C.prod_id
                  FROM pu_characteristics C 
                  JOIN product_group_data G ON C.prod_id = G.prod_id
                 WHERE prop_id = @Prop_Id AND char_id = @Char_Id AND product_grp_id = @Group_Id
              )
    ORDER BY TimeStamp ASC
  END
Else If @QueryType = @GroupAndPropertyNOEndDescend 	 --14
  BEGIN
       SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id 
         FROM gb_dset ds  WITH (index(dset_by_pu)) 
         LEFT OUTER JOIN gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
        WHERE ds.pu_id = @Pu_Id AND TimeStamp = @Start_Time
          AND prod_id IN 
              ( SELECT C.prod_id
                  FROM pu_characteristics C 
                  JOIN product_group_data G ON C.prod_id = G.prod_id
                 WHERE prop_id = @Prop_Id AND char_id = @Char_Id AND product_grp_id = @Group_Id
              )
    ORDER BY TimeStamp DESC
  END
Else If @QueryType = @GroupAndPropertyYesEndAscend 	 -- 15
  BEGIN
      SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id 
        FROM gb_dset ds  WITH (index(dset_by_pu)) 
        LEFT OUTER JOIN gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
       WHERE ds.pu_id = @Pu_Id AND TimeStamp BETWEEN @Start_Time AND @End_Time
         AND prod_id IN 
             ( SELECT C.prod_id
                 FROM pu_characteristics C 
                 JOIN product_group_data G ON C.prod_id = G.prod_id
                WHERE prop_id = @Prop_Id AND char_id = @Char_Id AND product_grp_id = @Group_Id
             )
    ORDER BY TimeStamp ASC
  END
Else If @QueryType = @GroupAndPropertyYesEndDescend 	 -- 16
  BEGIN
      SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id 
        FROM gb_dset ds  WITH (index(dset_by_pu)) 
        LEFT OUTER JOIN gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
       WHERE ds.pu_id = @Pu_Id AND TimeStamp BETWEEN @Start_Time AND @End_Time
         AND prod_id IN 
             ( SELECT C.prod_id
                 FROM pu_characteristics C 
                 JOIN product_group_data G ON C.prod_id = G.prod_id
                WHERE prop_id = @Prop_Id AND char_id = @Char_Id AND product_grp_id = @Group_Id
             )
    ORDER BY TimeStamp DESC
  END
--EndIf
GOTO EXIT_PROCEDURE
-- **************************************************************************************************
-- **************************************************************************************************
-- **************************************************************************************************
-- **************************************************************************************************
DO_INCLUDE_PRODUCT_CODE_SQL:
  If @QueryType = @NoProductNOEndAscend   --17
    BEGIN
        SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, p.Prod_Code, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id
          FROM gb_dset ds  WITH (index(dset_by_pu))
          LEFT OUTER JOIN gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
          JOIN Products p ON p.Prod_Id = ds.Prod_Id
         WHERE ds.pu_id = @Pu_Id AND TimeStamp = @Start_Time
      ORDER BY TimeStamp ASC
    END
  Else If @QueryType = @NoProductNOEndDescend --18
    BEGIN
        SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, p.Prod_Code, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id
          FROM gb_dset ds  WITH (index(dset_by_pu))
          LEFT OUTER JOIN gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
          JOIN Products p ON p.Prod_Id = ds.Prod_Id
         WHERE ds.pu_id = @Pu_Id AND TimeStamp = @Start_Time
      ORDER BY TimeStamp DESC
    END
  Else If @QueryType = @NoProductYesEndAscend --19
    BEGIN
        SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, p.Prod_Code, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id
          FROM gb_dset ds  WITH (index(dset_by_pu))
          LEFT OUTER JOIN  gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
          JOIN Products p ON p.Prod_Id = ds.Prod_Id
         WHERE ds.pu_id = @Pu_Id AND TimeStamp BETWEEN @Start_Time AND @End_Time
      ORDER BY TimeStamp ASC
    END
  Else If @QueryType = @NoProductYesEndDescend  --20
    BEGIN
        SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, p.Prod_Code, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id
          FROM gb_dset ds  WITH (index(dset_by_pu))
          LEFT OUTER JOIN gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
          JOIN Products p ON p.Prod_Id = ds.Prod_Id
         WHERE ds.pu_id = @Pu_Id AND TimeStamp BETWEEN @Start_Time AND @End_Time
      ORDER BY TimeStamp DESC
    END
  Else If @QueryType = @SingleProductNOEndAscend  --1
    BEGIN
        SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, p.Prod_Code, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id
          FROM gb_dset ds  WITH (index(dset_by_pu))
          LEFT OUTER JOIN gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
          JOIN Products p ON p.Prod_Id = ds.Prod_Id
         WHERE ds.pu_id = @Pu_Id AND ds.TimeStamp = @Start_Time AND ds.prod_id = @Prod_Id
      ORDER BY TimeStamp ASC
    END
  Else If @QueryType = @SingleProductNOEndDescend --2
    BEGIN
        SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, p.Prod_Code, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id
          FROM gb_dset ds  WITH (index(dset_by_pu))
          LEFT OUTER JOIN gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
          JOIN Products p ON p.Prod_Id = ds.Prod_Id
         WHERE ds.pu_id = @Pu_Id AND ds.TimeStamp = @Start_Time AND ds.prod_id = @Prod_Id
      ORDER BY ds.TimeStamp DESC
    END
  Else If @QueryType = @SingleProductYesEndAscend --3
    BEGIN
        SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, p.Prod_Code, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id
          FROM gb_dset ds  WITH (index(dset_by_pu))
          LEFT OUTER JOIN  gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
          JOIN Products p ON p.Prod_Id = ds.Prod_Id
         WHERE ds.pu_id = @Pu_Id AND ds.TimeStamp BETWEEN @Start_Time AND @End_Time AND ds.prod_id = @Prod_Id
      ORDER BY TimeStamp ASC
    END
  Else If @QueryType = @SingleProductYesEndDescend  --4
    BEGIN
        SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, p.Prod_Code, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id
          FROM gb_dset ds  WITH (index(dset_by_pu))
          LEFT OUTER JOIN  gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
          JOIN Products p ON p.Prod_Id = ds.Prod_Id
         WHERE ds.pu_id = @Pu_Id AND TimeStamp BETWEEN @Start_Time AND @End_Time AND ds.prod_id = @Prod_Id
      ORDER BY TimeStamp DESC
    END
  Else If @QueryType = @GroupNOEndAscend      --5
    BEGIN
        SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, p.Prod_Code, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id
          FROM gb_dset ds  WITH (index(dset_by_pu))
          LEFT OUTER JOIN  gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
          JOIN Products p ON p.Prod_Id = ds.Prod_Id
         WHERE ds.pu_id = @Pu_Id AND  ds.TimeStamp = @Start_Time
           AND ds.prod_id in ( Select g.prod_id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
      ORDER BY TimeStamp ASC
    END
  Else If @QueryType = @GroupNOEndDescend     --6
    BEGIN
        SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, p.Prod_Code, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id
          FROM gb_dset ds  WITH (index(dset_by_pu))
          LEFT OUTER JOIN  gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
          JOIN Products p ON p.Prod_Id = ds.Prod_Id
         WHERE ds.pu_id = @Pu_Id AND ds.TimeStamp = @Start_Time
           AND ds.prod_id in ( Select g.prod_id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
      ORDER BY TimeStamp DESC
    END
  Else If @QueryType = @GroupYesEndAscend     --7
    BEGIN
        SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, p.Prod_Code, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id
          FROM gb_dset ds  WITH (index(dset_by_pu))
          LEFT OUTER JOIN gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
          JOIN Products p ON p.Prod_Id = ds.Prod_Id
         WHERE ds.pu_id = @Pu_Id AND ds.TimeStamp BETWEEN @Start_Time AND @End_Time
           AND ds.prod_id in ( SELECT g.prod_id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
      ORDER BY ds.TimeStamp ASC
    END
  Else If @QueryType = @GroupYesEndDescend    --8
    BEGIN
        SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, p.Prod_Code, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id
          FROM gb_dset ds  WITH (index(dset_by_pu))
          LEFT OUTER JOIN gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
          JOIN Products p ON p.Prod_Id = ds.Prod_Id
         WHERE ds.pu_id = @Pu_Id AND ds.TimeStamp BETWEEN @Start_Time AND @End_Time
           AND ds.prod_id in ( SELECT g.prod_id FROM product_group_data g WHERE g.product_grp_id = @Group_Id )
      ORDER BY ds.TimeStamp DESC
    END
  Else If @QueryType = @CharacteristicNOEndAscend   --9
    BEGIN
        SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, p.Prod_Code, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id
          FROM gb_dset ds  WITH (index(dset_by_pu))
          LEFT OUTER JOIN  gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
          JOIN Products p ON p.Prod_Id = ds.Prod_Id
         WHERE ds.pu_id = @Pu_Id AND ds.TimeStamp = @Start_Time
           AND ds.prod_id IN ( SELECT c.prod_id FROM  pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
      ORDER BY ds.TimeStamp ASC
    END
  Else If @QueryType = @CharacteristicNOEndDescend  --10
    BEGIN
        SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, p.Prod_Code, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id
          FROM gb_dset ds  WITH (index(dset_by_pu))
          LEFT OUTER JOIN  gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
          JOIN Products p ON p.Prod_Id = ds.Prod_Id
         WHERE ds.pu_id = @Pu_Id AND ds.TimeStamp = @Start_Time
           AND ds.prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
      ORDER BY ds.TimeStamp DESC
    END
  Else If @QueryType = @CharacteristicYesEndAscend  --11
    BEGIN
        SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, p.Prod_Code, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id
          FROM gb_dset ds  WITH (index(dset_by_pu))
          LEFT OUTER JOIN  gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
          JOIN Products p ON p.Prod_Id = ds.Prod_Id
         WHERE ds.pu_id = @Pu_Id AND ds.TimeStamp BETWEEN @Start_Time AND @End_Time
           AND ds.prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
      ORDER BY ds.TimeStamp ASC
    END
  Else If @QueryType = @CharacteristicYesEndDescend --12
    BEGIN
        SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, p.Prod_Code, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id
          FROM gb_dset ds  WITH (index(dset_by_pu))
          LEFT OUTER JOIN  gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
          JOIN Products p ON p.Prod_Id = ds.Prod_Id
         WHERE ds.pu_id = @Pu_Id AND ds.TimeStamp BETWEEN @Start_Time AND @End_Time
           AND ds.prod_id IN ( SELECT c.prod_id FROM pu_characteristics c WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id )
      ORDER BY ds.TimeStamp DESC
    END
  Else If @QueryType = @GroupAndPropertyNOEndAscend --13
    BEGIN
         SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, p.Prod_Code, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id
           FROM gb_dset ds  WITH (index(dset_by_pu))
           LEFT OUTER JOIN gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
           JOIN Products p ON p.Prod_Id = ds.Prod_Id
          WHERE ds.pu_id = @Pu_Id AND ds.TimeStamp = @Start_Time
            AND ds.prod_id IN
                ( SELECT C.prod_id
                    FROM pu_characteristics C
                    JOIN product_group_data G ON C.prod_id = G.prod_id
                   WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id AND g.product_grp_id = @Group_Id
                )
      ORDER BY ds.TimeStamp ASC
    END
  Else If @QueryType = @GroupAndPropertyNOEndDescend  --14
    BEGIN
         SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, p.Prod_Code, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id
           FROM gb_dset ds  WITH (index(dset_by_pu))
           LEFT OUTER JOIN gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
           JOIN Products p ON p.Prod_Id = ds.Prod_Id
          WHERE ds.pu_id = @Pu_Id AND ds.TimeStamp = @Start_Time
            AND ds.prod_id IN
                ( SELECT C.prod_id
                    FROM pu_characteristics C
                    JOIN product_group_data G ON C.prod_id = G.prod_id
                   WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id AND g.product_grp_id = @Group_Id
                )
      ORDER BY ds.TimeStamp DESC
    END
  Else If @QueryType = @GroupAndPropertyYesEndAscend  -- 15
    BEGIN
        SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, p.Prod_Code, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id
          FROM gb_dset ds  WITH (index(dset_by_pu))
          LEFT OUTER JOIN gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
          JOIN Products p ON p.Prod_Id = ds.Prod_Id
         WHERE ds.pu_id = @Pu_Id AND ds.TimeStamp BETWEEN @Start_Time AND @End_Time
           AND ds.prod_id IN
               ( SELECT C.prod_id
                   FROM pu_characteristics C
                   JOIN product_group_data G ON C.prod_id = G.prod_id
                  WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id AND g.product_grp_id = @Group_Id
               )
      ORDER BY ds.TimeStamp ASC
    END
  Else If @QueryType = @GroupAndPropertyYesEndDescend -- 16
    BEGIN
        SELECT [timestamp] = ds.timestamp at time zone @DBTz at time zone @InTimeZone, p.Prod_Code, ds.prod_id, dsd.*, Data_Type_Id = @Data_Type_Id
          FROM gb_dset ds  WITH (index(dset_by_pu))
          LEFT OUTER JOIN gb_dset_data dsd  WITH (index(gb_dset_by_id)) ON ds.dset_id = dsd.dset_id AND dsd.var_id = @Var_Id
          JOIN Products p ON p.Prod_Id = ds.Prod_Id
         WHERE ds.pu_id = @Pu_Id AND ds.TimeStamp BETWEEN @Start_Time AND @End_Time
           AND ds.prod_id IN
               ( SELECT C.prod_id
                   FROM pu_characteristics C
                   JOIN product_group_data G ON C.prod_id = G.prod_id
                  WHERE c.prop_id = @Prop_Id AND c.char_id = @Char_Id AND g.product_grp_id = @Group_Id
               )
      ORDER BY ds.TimeStamp DESC
    END
  --EndIf
  GoTo EXIT_PROCEDURE
-- **************************************************************************************************
-- **************************************************************************************************
-- **************************************************************************************************
-- **************************************************************************************************
EXIT_PROCEDURE:
