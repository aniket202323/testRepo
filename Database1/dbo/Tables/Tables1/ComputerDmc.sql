CREATE TABLE [dbo].[ComputerDmc] (
    [DefaultUserName]                  NVARCHAR (255)  NULL,
    [DefaultUserPwd]                   NVARCHAR (255)  NULL,
    [Autologin]                        BIT             NULL,
    [Autologout]                       BIT             NULL,
    [AutologoutTimeout]                INT             NULL,
    [Lockdown]                         BIT             NULL,
    [LinkedEquipmentEntryPointAddress] NVARCHAR (1024) NULL,
    [LinkedEquipmentObjectAddress]     NVARCHAR (1024) NULL,
    [ComputerDmcType]                  NVARCHAR (255)  NOT NULL,
    [ComputerDmcName]                  NVARCHAR (255)  NOT NULL,
    [OverrideDefaultConfiguration]     BIT             NULL,
    [AutologinWindowsUser]             BIT             NULL,
    PRIMARY KEY CLUSTERED ([ComputerDmcType] ASC, [ComputerDmcName] ASC),
    CONSTRAINT [ComputerDmc_ITModelObject_Relation1] FOREIGN KEY ([ComputerDmcType], [ComputerDmcName]) REFERENCES [dbo].[ITModelObject] ([Type], [Name])
);

