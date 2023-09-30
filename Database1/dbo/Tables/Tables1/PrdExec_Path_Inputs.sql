CREATE TABLE [dbo].[PrdExec_Path_Inputs] (
    [PEPI_Id]               INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Allow_Manual_Movement] BIT NOT NULL,
    [Alternate_Spec_Id]     INT NULL,
    [Event_Subtype_Id]      INT NULL,
    [Hide_Input]            BIT NOT NULL,
    [Lock_Inprogress_Input] BIT NOT NULL,
    [Path_Id]               INT NOT NULL,
    [PEI_Id]                INT NOT NULL,
    [Primary_Spec_Id]       INT NULL,
    CONSTRAINT [PrdExecPathInputs_PK_PEPIId] PRIMARY KEY CLUSTERED ([PEPI_Id] ASC),
    CONSTRAINT [PrdExecPathInputs_FK_AltSpec] FOREIGN KEY ([Alternate_Spec_Id]) REFERENCES [dbo].[Specifications] ([Spec_Id]),
    CONSTRAINT [PrdExecPathInputs_FK_EventSub] FOREIGN KEY ([Event_Subtype_Id]) REFERENCES [dbo].[Event_Subtypes] ([Event_Subtype_Id]),
    CONSTRAINT [PrdExecPathInputs_FK_PEInputs] FOREIGN KEY ([PEI_Id]) REFERENCES [dbo].[PrdExec_Inputs] ([PEI_Id]),
    CONSTRAINT [PrdExecPathInputs_FK_PrdExecPath] FOREIGN KEY ([Path_Id]) REFERENCES [dbo].[Prdexec_Paths] ([Path_Id]),
    CONSTRAINT [PrdExecPathInputs_FK_PrimSpec] FOREIGN KEY ([Primary_Spec_Id]) REFERENCES [dbo].[Specifications] ([Spec_Id])
);

