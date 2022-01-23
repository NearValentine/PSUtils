# AZ1_Projekt

$csv = "c:\xd\u�ytkownicy.csv"
$domain = Get-ADDomain
$folder = "c:\xd\"
$count = 0

# Generator hase�
$newPass = ''
1..12 | ForEach-Object {$newPass += [char](Get-Random -Minimum 48 -Maximum 122)}

# Funkcja tworz�ca lokalizacje, wkt�rej bed� znajdowa� si� wszystkie pliki wynikowe
function folder
{
    if(Test-Path $folder){}
    else{New-Item -Path $folder -ItemType Directory -Force}
}

# Funkcja menu g��wnego, s�u�y do wybrania po��danego dzia�ania
function menu
{
 cls
 $opcja = Read-Host "Prosz� wybra� opcje:`n 1 � Obs�uga kont u�ytkownik�w`n 2 - Obs�uga kont grup`n 3 - Raporty`n q - Wyjd�"`n
 if($opcja -eq 1){a}
 elseif($opcja -eq 2){b}
 elseif($opcja -eq 3){c}
 elseif($opcja -eq 'q'){break}
  else
    {
     Write-Host "B��d - Wybierz poprawn� opcj�" -ForegroundColor Red
     Sleep 2
     menu
    }
}

# Podmenu do obs�ugi kont u�ytkownik�w
function a
{
 cls
 $opcja = Read-Host "Prosz� wybra� opcje:`n 1 � Tworzenie konta u�ytkownika`n 2 - Tworzenie wielu kont na podstawie pliku csv`n 3 - Blokowanie konta u�ytkownika`n 4 - Zmiana has�a konta u�ytkownika`n q - Wr��"`n
 if($opcja -eq 1){tworzenie_konta}
 elseif($opcja -eq 2){csv}
 elseif($opcja -eq 3){blokada_konta}
 elseif($opcja -eq 4){zmiana_hasla}
  elseif($opcja -eq 'q'){menu}
 else
    {
     Write-Host "B��d - Wybierz poprawn� opcj�" -ForegroundColor Red
     Sleep 2
     a
    }
}

# Podmenu do obs�ugi kont grup
function b
{
 cls
 $opcja = Read-Host "Prosz� wybra� opcje:`n 1 � Tworzenie nowych grup`n 2 - Dodawanie u�ytkownik�w do grup`n q - Wr��"`n
 if($opcja -eq 1){tworzenie_grupy}
 elseif($opcja -eq 2){dodanie_do_grupy}
  elseif($opcja -eq 'q'){menu}
 else
    {
     Write-Host "B��d - Wybierz poprawn� opcj�" -ForegroundColor Red
     Sleep 2
     b
    }
}

# Podmenu do raport�w
function c
{
 cls
 $opcja = Read-Host "Prosz� wybra� opcje:`n 1 � Lista grup z cz�onkami`n 2 - Lista zablokowanych kont w domenie`n 3 - Lista szczeg�owych informacji o kontach u�ytkownik�w`n 4 - Lista szczeg�owych informacji o kontach komputer�w w domenie`n 5 - Lista jednostek organizacyjnych w domenie`n q - Wr��"`n
 if($opcja -eq 1){lista_grup}
 elseif($opcja -eq 2){lista_kont_blok}
 elseif($opcja -eq 3){lista_konta}
 elseif($opcja -eq 4){lista_komp}
 elseif($opcja -eq 5){lista_ou}
 elseif($opcja -eq 'q'){menu}
 else
    {
     Write-Host "B��d - Wybierz poprawn� opcj�" -ForegroundColor Red
     Sleep 2
     c
    }
}

# Funkcja tworz�ca konto u�ytkownika
function tworzenie_konta
{
    [CmdletBinding()]
    param(
    [Parameter(Mandatory=$true)]
    [string]$name,
    [Parameter(Mandatory=$true)]
    [string]$surname,
    [Parameter(Mandatory=$true)]
    [string]$department
    )
    $logindns = "$($name).$($surname)"
    $logindns2 = $logindns+"@"+$domain.DNSRoot
    $username = "$($name) $($surname)"
    $count = 0
    $file = $folder+"$($username).csv" 
    while((Get-ADuser -Filter {SamAccountName -eq $logindns}))
    {
        $count++
        $logindns = $logindns + [string]$count
        $logindns2 = $logindns+"@"+$domain.DNSRoot
        $username = $username + [string]$count
        $file = $folder+"$($username).csv"
    }
    New-ADUser -DisplayName:$username -EmailAddress:$logindns2 -Department:$department -GivenName:$name -Name:$username -SamAccountName:$logindns -Surname:$surname -Type:"user" -UserPrincipalName:$logindns2 -AccountPassword (ConvertTo-SecureString $newPass -AsPlainText -Force) -Enabled:$true
    Get-ADUser $logindns | Export-Csv $file -NoTypeInformation
    "Password: " + $newPass >> $file
    $log = "Creator User Date" | ConvertFrom-String | Export-Csv -Path $folder"create_user.csv" -NoClobber -NoTypeInformation
    $who = Get-ADUser $env:USERNAME 
    $date = Get-Date -Format "MM/dd/yyyy HH:mm"
    $log = "$($who.Name);$username;$date" | ConvertFrom-String -Delimiter ";" | Export-Csv -Path $folder"create_user.csv" -NoClobber -NoTypeInformation -Append
    a
}

# Funkcja tworz�ca wiele kont na podstawie pliku csv
function tworzenie_konta_csv
{
    $users = Import-Csv $csv
    Foreach ($user in $users)
    {  
        $dane = [pscustomobject]@{
                    Name = $user.imie + " " + $user.nazwisko
                    GivenName = $user.imie
                    Surname = $user.nazwisko
                    Department = $user.dzial
                    UserPrincipalName = $user.imie + "." + $user.nazwisko + "@" + $domain.DNSRoot
                    SamAccountName = $user.imie + "." + $user.nazwisko
                    DisplayName = $user.imie + " " + $user.nazwisko
                    EmailAddress = $user.imie + "." + $user.nazwisko + "@" + $domain.DNSRoot
                    AccountPassword = ConvertTo-SecureString $newPass -AsPlainText -Force
                    Enabled = $true
                 }
        $count = 0
        $adusers = Get-ADUser -Filter * | Select-Object SamAccountName | % {
        $aduser = $_
        if ($aduser.SamAccountName -eq $dane.SamAccountName)
        {
            $count++
            $dane.SamAccountName = $dane.SamAccountName + [string]$count
            $dane.UserPrincipalName = $dane.SamAccountName+"@"+$domain.DNSRoot
            $dane.Name = $dane.Name + [string]$count
        }     
        }
        $dane | New-ADUser -PassThru
        $log = "Creator User Date" | ConvertFrom-String | Export-Csv -Path $folder"create_user.csv" -NoClobber -NoTypeInformation
        $who = Get-ADUser $env:USERNAME 
        $date = Get-Date -Format "MM/dd/yyyy HH:mm"
        $log = "$($who.Name);$($dane.Name);$date" | ConvertFrom-String -Delimiter ";" | Export-Csv -Path $folder"create_user.csv" -NoClobber -NoTypeInformation -Append
    }
    a
}

# Funkcja generuj�ca pusty plik csv
function csv
{
    cls
    $opcja = Read-Host "Prosz� wybra� opcje:`n 1 - Tworzenie wielu kont na podstawie pliku csv`n 2 - Generuj pusty csv`n q - Wr��"`n
    if($opcja -eq 1){tworzenie_konta_csv}
    elseif($opcja -eq 2){
                            $header = "imie","nazwisko","dzial" | Select-Object imie,nazwisko,dzial | Export-Csv -Path $csv -NoClobber -NoTypeInformation
                            a
                        }
    elseif($opcja -eq 'q'){a}
    else
    {
        Write-Host "B��d - Wybierz poprawn� opcj�" -ForegroundColor Red
        Sleep 2
        a
    }
}

# Funkcja blokuj�ca konto u�ytkownika
function blokada_konta
{
    cls
    $block = Read-Host "Prosz� wpisa� login do zablokowania: "`n
    Get-ADUser -Filter 'SamAccountName -like $block' | Disable-ADAccount
    $nazwa = Get-ADUser -Filter 'SamAccountName -like $block' | Select-Object Name
    $who = Get-ADUser $env:USERNAME
    $date = Get-Date -Format "MM/dd/yyyy HH:mm"
    $log = "$($who.Name);$($nazwa.Name);$date" | Out-File -FilePath $folder"zablokowane_konta.txt" -Append
    a
}

# Funkcja zmieniaj�ca has�o u�ytkownika
function zmiana_hasla
{
    cls
    $konto = Read-Host "Prosz� wpisa� login do zmiany has�a: "`n
    $haslo = Read-Host "Prosze wpisa� nowe has�o: "`n
    $konto1 = Get-ADUser -Filter 'SamAccountName -like $konto'
    Set-ADAccountPassword -Identity $konto1 -NewPassword (ConvertTo-SecureString -AsPlainText $haslo -Force)
    $nazwa = Get-ADUser -Filter 'SamAccountName -like $konto' | Select-Object Name
    $who = Get-ADUser $env:USERNAME
    $date = Get-Date -Format "MM/dd/yyyy HH:mm"
    $log = "$($who.Name);$($nazwa.Name);$date" | Out-File -FilePath $folder"zmiana_hasla.txt" -Append
    a
}

# Funkcja tworz�ca konto grupy
function tworzenie_grupy
{
    cls
    $grupa = Read-Host "Prosz� wpisa� nazw� grupy: "`n
    $check = Get-ADGroup $grupa
    if($check)
    {
        Write-Host "ta grupa juz istnieje" -ForegroundColor Green
        Sleep 2
        b
    }
    else
    {
        New-ADGroup -Name:$grupa -SamAccountName:$grupa -GroupScope:"Global"
        $who = Get-ADUser $env:USERNAME 
        $date = Get-Date -Format "MM/dd/yyyy HH:mm"
        $log = "Creator Group Date" | ConvertFrom-String | Export-Csv -Path $folder"create_group.csv" -NoClobber -NoTypeInformation
        $log = "$($who.Name);$grupa;$date" | ConvertFrom-String -Delimiter ";" | Export-Csv -Path $folder"create_group.csv" -NoClobber -NoTypeInformation -Append
    }
    b
}

# Funkcja dodaj�ca konto u�ytkownika do grupy
function dodanie_do_grupy
{
    cls
    $grupa = Read-Host "Prosz� wpisa� nazw� grupy: "`n
    $check = Get-ADGroup $grupa
    if(!$check)
    {
        Write-Host "ta grupa nie istnieje" -ForegroundColor Red
        Sleep 2
        b
    }
    else
    {
        $user = Read-Host "Prosz� wpisa� login u�ytkownika: "`n
        $checkuser = Get-ADUser -Filter 'SamAccountName -like $user'
        if(!$checkuser)
        {
            Write-Host "ten u�ytkownik nie istnieje" -ForegroundColor Red
            Sleep 2
            b
        }
        else
        {
            Add-ADGroupMember -Identity $grupa -Members $user
            $who = Get-ADUser $env:USERNAME
            $log = "$($who.Name);$user;$grupa" | Out-File -FilePath $folder"zmiana_czlonkostwa_grup.txt" -Append
        }
    }
    b
}

# Funkcja generuj�ca raport z list� grup z cz�onkami
function lista_grup
{
    Get-ADGroup -Filter * | Select-Object Name | % {
    $grupa = $_
    New-Item -Path $folder"$($grupa.Name).txt"
    Get-ADGroupMember $grupa.Name | Select-Object SamAccountName | Out-File -FilePath $folder"$($grupa.Name).txt"
    }
    c
}

# Funkcja generuj�ca raport z list� zablokowanych kont
function lista_kont_blok
{
    Get-ADUser -Filter {Enabled -eq $false} -properties WhenChanged | Select Name,DistinguishedName,SID,WhenChanged | Export-Csv -Path $folder"zablokowane_konta.csv" -NoClobber -NoTypeInformation
    c
}

# Funkcja generuj�ca raport z list� u�ytkownik�w
function lista_konta
{
    Get-ADUser -Filter * -Properties whenCreated,whenChanged,LastLogonDate,PasswordLastSet | Select GivenName,Surname,UserPrincipalName,SamAccountName,DistinguishedName,whenCreated,whenChanged,LastLogonDate,PasswordLastSet | Export-Csv -Path $folder"u�ytkownicy.csv" -NoClobber -NoTypeInformation
    c
}

# Funkcja generuj�ca raport z list� komputer�w
function lista_komp
{
    Get-ADComputer -Filter * -Properties Enabled,PasswordLastSet,whenCreated,OperatingSystem | % {
    $komputery = $_
    $komputery | Select Name,SID,DistinguishedName,Enabled,PasswordLastSet,whenCreated | Export-Csv -Path $folder"$($komputery.DNSHostName)_$($komputery.OpeatingSystem).csv" -NoClobber -NoTypeInformation
    }
    c
}

# Funkcja generuj�ca raport z list� jednostek organizacyjnych w domenie
function lista_ou
{
    Get-ADOrganizationalUnit -Filter * -Properties Name,DistinguishedName | Select Name,DistinguishedName | Export-Csv -Path $folder"OS.csv" -NoClobber -NoTypeInformation
    c
}

cls # Wyczyszczenie konsoli
folder # Utworzenie miejsca na wszystkie pliki i raporty
menu # Wywo�anie g��wnej funkcji
