CREATE PROCEDURE dbo.spEM_PutEventConfig
  @EC_Id             int,
  @Is_Active         bit,
  @PU_Id             int,
  @ET_Id             int,
  @Event_Subtype     int,
  @Field1            nvarchar(60),
  @Field2            nvarchar(60),
  @Field3            nvarchar(60),
  @Field4            nvarchar(60),
  @Field5            nvarchar(60),
  @Field6            nvarchar(60),
  @Field7            nvarchar(60),
  @Field8            nvarchar(60),
  @Field9            nvarchar(60),
  @Field10           nvarchar(60),
  @Field11           nvarchar(60),
  @Field12           nvarchar(60),
  @Field13           nvarchar(60),
  @Field14           nvarchar(60),
  @Field15           nvarchar(60),
  @Field16           nvarchar(60),
  @Field17           nvarchar(60),
  @Field18           nvarchar(60),
  @Field19           nvarchar(60),
  @Field20           nvarchar(60),
  @Field21           nvarchar(60),
  @Field22           nvarchar(60),
  @Field23           nvarchar(60),
  @Field24           nvarchar(60),
  @Field25           nvarchar(60),
  @Field26           nvarchar(60),
  @Field27           nvarchar(60),
  @Field28           nvarchar(60),
  @Field29           nvarchar(60),
  @Field30           nvarchar(60),
  @UserId 	   Int,
  @NewEC_Id          int  OUTPUT 
AS
  --
  -- Begin a transaction.
  --
  --
  --
  --
  -- Update the variable.
  --
 /* Declare @ED_Model_Id int
  SELECT @ED_Model_Id = ED_Model_Id 
    FROM ED_Models
    WHERE Model_Num = @Event_Subtype
  IF @EC_Id IS NULL
   BEGIN
  SELECT @ED_Model_Id = ED_Model_Id 
    FROM ED_Models
    WHERE Model_Num = @Event_Subtype
   INSERT INTO Event_Configuration (Is_Active,PU_Id,Event_Subtype_Id, ED_Model_Id)
      VALUES(@Is_Active, @PU_id, NULL, @ED_Model_Id) 
     SELECT @NewEC_Id = Scope_Identity()
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field1 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 1
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field2 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 2
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field3 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 3
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field4 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 4
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field5 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 5
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field6 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 6
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field7 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 7
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field8 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 8
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field9 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 9
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field10 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 10
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field11 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 11
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field12 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 12
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field13 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 13
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field14 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 14
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field15 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 15
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field16 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 16
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field17 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 17
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field18 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 18
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field19 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 19
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field20 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 20
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field21 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 21
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field22 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 22
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field23 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 23
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field24 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 24
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field25 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 25
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field26 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 26
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field27 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 27
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field28 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 28
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field29 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 29
    INSERT INTO Event_Configuration_Data (EC_Id, ED_Field_Id, Value)
      SELECT @NewEC_Id, ED_Field_Id, @Field30 FROM ED_Fields WHERE ED_Model_Id = @ED_Model_Id and Field_Order = 30
   END
  ELSE
    BEGIN
  SELECT @ED_Model_Id = ED_Model_Id 
    FROM Event_configuration
    WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration
       SET Is_Active    = @Is_Active
        WHERE EC_Id = @EC_Id
      SELECT @NewEC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field1
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 1 
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field2
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 2
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field3
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 3
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field4
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 4
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field5
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 5
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field6
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 6
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field7
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 7
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field8
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 8
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field9
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 9
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field10
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 10
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field11
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 11
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field12
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 12
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field13
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 13
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field14
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 14
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field15
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 15
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field16
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 16
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field17
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 17
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field18
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 18
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field19
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 19
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field20
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 20
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field21
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 21
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field22
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 22
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field23
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 23
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field24
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 24
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field25
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 25
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field26
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 26
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field27
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 27
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field28
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 28
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field29
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 29
        WHERE EC_Id = @EC_Id
      UPDATE Event_Configuration_Data Set Value = @Field30
        FROM Event_Configuration_Data d JOIN ED_Fields f on f.ED_Model_id = @ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.Field_Order = 30
        WHERE EC_Id = @EC_Id
    END
Finish:
*/
  RETURN(1)
