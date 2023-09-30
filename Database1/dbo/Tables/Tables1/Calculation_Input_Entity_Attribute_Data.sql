CREATE TABLE [dbo].[Calculation_Input_Entity_Attribute_Data] (
    [CIEA_Id]                 INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Calc_Input_Attribute_Id] INT NOT NULL,
    [Calc_Input_Entity_Id]    INT NOT NULL,
    CONSTRAINT [Calculation_Input_Entity_Attribute_Data_PK] PRIMARY KEY NONCLUSTERED ([CIEA_Id] ASC),
    CONSTRAINT [CalculationInputEntityAttributeData_FK_Calc_InputEntityId] FOREIGN KEY ([Calc_Input_Entity_Id]) REFERENCES [dbo].[Calculation_Input_Entities] ([Calc_Input_Entity_Id]),
    CONSTRAINT [CalculationInputEntityAttributeData_FK_CalcInputAttributeId] FOREIGN KEY ([Calc_Input_Attribute_Id]) REFERENCES [dbo].[Calculation_Input_Attributes] ([Calc_Input_Attribute_Id])
);


GO
CREATE NONCLUSTERED INDEX [Calculation_Input_Entity_Attribute_Data_UC_AttrEnt]
    ON [dbo].[Calculation_Input_Entity_Attribute_Data]([Calc_Input_Attribute_Id] ASC, [Calc_Input_Entity_Id] ASC);

