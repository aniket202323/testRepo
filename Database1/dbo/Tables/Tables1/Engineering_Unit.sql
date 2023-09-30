CREATE TABLE [dbo].[Engineering_Unit] (
    [Eng_Unit_Id]   INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Eng_Unit_Code] VARCHAR (15) NOT NULL,
    [Eng_Unit_Desc] VARCHAR (50) NOT NULL,
    [Is_Active]     BIT          CONSTRAINT [EngineeringUnit_DF_IsActive] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [EngineeringUnit_PK_EngUnitId] PRIMARY KEY NONCLUSTERED ([Eng_Unit_Id] ASC),
    CONSTRAINT [EngineeringUnit_CC_EmptyCode] CHECK (len([Eng_Unit_Code])>(0)),
    CONSTRAINT [EngineeringUnit_CC_EmptyDesc] CHECK (len([Eng_Unit_Desc])>(0)),
    CONSTRAINT [EngineeringUnit_UC_EUCode] UNIQUE NONCLUSTERED ([Eng_Unit_Code] ASC),
    CONSTRAINT [EngineeringUnit_UC_EUDesc] UNIQUE NONCLUSTERED ([Eng_Unit_Desc] ASC)
);

