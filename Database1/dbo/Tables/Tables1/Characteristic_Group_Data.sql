CREATE TABLE [dbo].[Characteristic_Group_Data] (
    [CGD_Id]                INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Char_Id]               INT NOT NULL,
    [Characteristic_Grp_Id] INT NOT NULL,
    CONSTRAINT [CharGroupData_PK_CGDId] PRIMARY KEY CLUSTERED ([CGD_Id] ASC),
    CONSTRAINT [CharGroupData_FK_CharGrpId] FOREIGN KEY ([Characteristic_Grp_Id]) REFERENCES [dbo].[Characteristic_Groups] ([Characteristic_Grp_Id]),
    CONSTRAINT [CharGroupData_FK_CharId] FOREIGN KEY ([Char_Id]) REFERENCES [dbo].[Characteristics] ([Char_Id])
);

