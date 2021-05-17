Clear-Host

$nl = [System.Environment]::NewLine
$bankLog = $false

Class Bank
{
    [string]$Transaction
    [int]$Amount
    [string]$Date
    [int]$Total

    Bank([string]$_Transaction,[int]$_Amount,[string]$_Date,[int]$_Total)
    {

        $this.Transaction = $_Transaction
        $this.Amount = $_Amount
        $this.Date = $_Date
        $this.Total = $_Total
    }
}

Class Card
{
    [int]$Suite
    [int]$Number

    Card($_Suite, $_Number)
    {
        $this.Suite = $_Suite
        $this.Number = $_Number
    }

    [object]GetCard()
    {
        return [psObject]@{
            Suite = [suite]$this.Suite
            Number = $this.Number
        }
    }
}

Class Player
{
    $name
    [int]$money = 100

    Player($_name)
    {
        $this.name = $_name
    }

}

Enum Suite
{
    Club = 1
    Diamond = 2
    Heart = 3
    Spade = 4
}

function GetIcon
{
    param($suite)

    switch($suite)
    {

        1
        {return "♣"
        }
        2
        {return "♦"
        }
        3
        {return "♥"
        }
        4
        {return "♠"
        }
    }
}

function GetColor
{
    param($suite)

    switch($suite)
    {

        1
        {return "Black"
        }
        2
        {return "Red"
        }
        3
        {return "Red"
        }
        4
        {return "Black"
        }
    }
}

function Shuffle-Deck
{
    param(
        $deck
    )

    $newDeck = New-Object System.Collections.ArrayList

    while ($deck.Count -gt 0)
    {
        $cardNumber = get-random -Minimum 0 -Maximum $deck.Count
        $card = $deck[$cardNumber]

        $deck.Remove($deck[$cardNumber]) | out-null

        $newDeck.Add($card) | out-null
    }
    return $newDeck
}

function Calculate-Hand
{
    param(
        $hand
    )
    $tulos = 0
    $newSum = 0
    $newHand = New-Object System.Collections.ArrayList
    $options = New-Object System.Collections.ArrayList

    $hand.ForEach({
            if($_ -gt 10)
            {$_ = 10
            }
            $newHand.add($_) | out-null
        })

    if(!$newHand.Contains(1))
    {
        #normal case
        $options.add(($newHand | Measure-Object -sum).sum) | out-null

    } else
    {

        $sumwithoutA = ($newHand | Measure-Object -sum).sum - ($newHand |where {$_ -eq 1}).count
        $newSum = ($sumwithoutA + ($newHand | where {$_ -eq 1}).count)-1

        if($newSum + 11 -le 21)
        {
            $options.add(($newSum + 11)) | out-null
            if($newSum + 11 -ne 21)
            {
                $options.add(($newSum + 1)) | out-null
            }
        } else
        {
            $options.add(($newSum + 1)) | out-null
        }
    }
    return $options
}

function PrintOut-Card
{
    param($hand)

    $hand.ForEach({
            Write-Host "$(GetIcon -suite $_.suite) $(Switch ($_.Number){

            11 {"J"}
            12 {"Q"}
            13 {"K"}
            1  {"A"}
            default {$_}

        } )" -f $(GetColor -suite $_.suite) -b white
        })
}

function Get-CardFromDeck
{
    param(
        $hand,
        $deck
    )
    $card = $deck[0]
    $deck.Remove($deck[0]) | out-null
    $hand.add($card) | out-null
    $deck.add($card) | out-null
}

function Bet-Money
{
    param($player,$amount)

    if($amount -le $player.money)
    {

        $player.money -= $amount

    }
}

function Give-MoneyToPlayer
{
    param($player,$bet,$sum,$blackJack,[switch]$push)

    if($push)
    {
        $player.money += $bet
    } elseif ($sum -eq 21 -and $blackJack)
    {
        $player.money += ($bet * 2.5)
        if($bankLog)
        {Transaction-Bank -bet $($bet*1.5)
        }
    } else
    {
        $player.money += ($bet * 2)
        if($bankLog)
        {Transaction-Bank -bet $bet
        }
    }

}

function Play-Player
{
    param($hand, $sumPlayer, $sumHouse, $deck)

    do
    {

        $read = Read-Host "Hit?"

        if($read -ne "N")
        {
            Get-CardFromDeck -hand $hand -deck $deck
            $sumPlayer = Calculate-Hand -hand $hand.number
            write-host "Player hand, sum: $sumPlayer vs $sumHouse"
            PrintOut-Card -hand $hand
        }


    } until($sumPlayer -ge 21 -or $read -eq "N")

    return $sumPlayer
}

function Play-House
{
    param($hand,$sumPlayer,$sumHouse,$deck)

    do
    {
        Get-CardFromDeck -hand $hand -deck $deck
        $sumHouse = Calculate-Hand -hand $hand.number
        write-host "House hand, sum: $sumHouse"
        #PrintOut-Card -hand $hand

        if ($sumHouse -eq 21)
        {
            #PrintOut-Card -hand $hand
            break
        }
    } until ( ($sumHouse | measure -Maximum).maximum -gt ($sumPlayer | measure -Maximum).Maximum -or ($sumHouse | measure -Maximum).maximum -in 17..21)

    return $sumHouse
}

function Play-Sound
{
    param([switch]$win)

    if($win)
    {
        [console]::beep(262,80)
        [console]::beep(330,80)
        [console]::beep(392,80)
        [console]::beep(523,100)
    } else
    {
        [console]::beep(185,200)
        [console]::beep(131,800)
    }
}

function Transaction-Bank
{
    param($bet,[switch]$win)

    $path = "C:\_Powershell\BlackJack\bank.csv"
    $csvFile = Import-Csv $path
    $date = (Get-Date -Format g).ToString()
    [int]$total = $csvFile[-1].Total

    if ($win)
    {
        $total += $bet
        $bank = [Bank]::new('+',$bet,$date,$total)
        $Bank | select Transaction,Amount,Date,Total | Export-Csv $path -NoTypeInformation -Force -append
    } else
    {
        $total -= $bet
        $bank = [Bank]::new('-',$bet,$date,$total)
        $Bank | select Transaction,Amount,Date,Total | Export-Csv $path -NoTypeInformation -Force -append
    }

}

function Draw-Graph
{

    $path = "C:\_Powershell\BlackJack\bank.csv"
    $csvFile = Import-Csv $path

    $i = 0
    $bankMoney = foreach ($t in $csvFile.total)
    {
        "[$i, $t], "
        $i++
    }

    $html = @"
<html>
  <head>
    <script type='text/javascript' src='https://www.google.com/jsapi'></script>
    <script type='text/javascript'>
google.load('visualization', '1', {packages: ['corechart', 'line']});
google.setOnLoadCallback(drawBasic);
function drawBasic() {
      var data = new google.visualization.DataTable();
      data.addColumn('number', 'X');
      data.addColumn('number', 'Bank Money $');
      data.addRows([$bankMoney]);
      var options = {
        hAxis: {
          title: 'Hands'
        },
        vAxis: {
          title: 'Money $'
        }
      };
      var chart = new google.visualization.LineChart(document.getElementById('chart_div'));
      chart.draw(data, options);
    }
    </script>
<script src='https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js'></script>
<link rel='stylesheet' href='https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css'>
  </head>
  <body>
    <div id='chart_div' style='width: 900px; height: 400px;'></div>
  </body>
</html>
"@

    $html | out-file "C:\_Powershell\BlackJack\bank.html"

}

$yourName = Read-Host "Give your name"
$player = [player]::new($yourName)

# game loop
while($true)
{
    #empty deck array
    $deck = New-Object System.Collections.ArrayList

    #add cards in order to the empty deck array list
    1..4 | % {
        $suite = $_
        1..13 | % {
            $deck.Add([Card]::New($suite,$_)) | out-null
        }
    }

    #new array list for shuffled deck
    [System.Collections.ArrayList]$newDeck = Shuffle-Deck -deck $deck

    $playerHand = New-Object System.Collections.ArrayList
    $houseHand = New-Object System.Collections.ArrayList

    #ask bet until it's a integer and lower amount what the player can afford
    do
    {
        Clear-Host
        $bet = $null
        [string]$bet = Read-Host "How much (max: $($player.money) $) do you bet?"

        if ($bet -match "^\d+$")
        {
            [int]$bet = $bet
        }

    }until($bet -match "^\d+$" -and $bet -le $player.money )


    Bet-Money -player $player -amount $bet

    #get 2 cards each from deck
    0..3 | % {
        if($_ % 2 -eq 0)
        {
            Get-CardFromDeck -hand $playerHand -deck $newDeck
        } else
        {
            Get-CardFromDeck -hand $houseHand -deck $newDeck
        }
    }

    $sumHouse = $null
    $sumPlayer = $null

    $houseHandOne = Calculate-Hand -hand $houseHand[0].number

    $calcPL = Calculate-Hand -hand $playerHand.number
    $calcHouse = Calculate-Hand -hand $houseHand.number

    write-output "Player hand, sum: $calcPL vs $houseHandOne"
    PrintOut-Card -hand $playerHand

    $nl

    write-output "House hand, sum: $houseHandOne"
    PrintOut-Card -hand $houseHand[0]
    $blackJack = $false
    if($calcPL -eq 21 -or $calcHouse -eq 21)
    {
        PrintOut-Card -hand $houseHand[1]
        Write-Host "*** Blackjack! ***" -b green -f black
        $sumPlayer = $calcPL
        $sumHouse = $calcHouse
        $blackJack = $true

    } else
    {

        #player plays
        if (($calcPL | measure -Maximum).Maximum -ne 21)
        {
            $sumPlayer = Play-Player -hand $playerHand -sumPlayer $calcPL -sumHouse $houseHandOne -deck $newDeck
        }

        #house plays
        if (($calcHouse | measure -Maximum).Maximum -ne 21 -and $sumPlayer -lt 22 -and ($calcHouse | measure -Maximum).Maximum -lt ($sumPlayer | measure -Maximum).Maximum -and ($calcHouse | measure -Maximum).Maximum -notin 17..21)
        {

            $sumHouse = Play-House -hand $houseHand -sumPlayer $sumPlayer -sumHouse $calcHouse -deck $newDeck

        } else
        {
            $sumHouse = ($calcHouse | measure -Maximum).Maximum
        }
    }

    if( ($sumPlayer | measure -Maximum).Maximum -gt 21 -or ($sumHouse | measure -Maximum).Maximum -gt ($sumPlayer | measure -Maximum).Maximum -and ($sumHouse | measure -Maximum).Maximum -lt 22)
    {

        Write-Host "House wins..." -f red
        Write-Host "House hand($sumHouse):"
        PrintOut-Card -hand $houseHand
        if($bankLog)
        {Transaction-Bank -bet $bet -win
        }
        Play-Sound
    } elseif( ($sumPlayer | measure -Maximum).Maximum -eq ($sumHouse | measure -Maximum).Maximum -and ($sumPlayer | measure -Maximum).Maximum -le 21 -and ($sumHouse | measure -Maximum).Maximum -le 21)
    {
        Write-Host "Push..." -f Magenta
        Write-Host "House hand ($sumHouse):"
        PrintOut-Card -hand $houseHand
        Give-MoneyToPlayer -player $player -bet $bet -sum $sumPlayer -blackJack $blackJack -push
    } else
    {
        Write-Host "Player wins!" -f green
        Write-Host "House hand($sumHouse):"
        PrintOut-Card -hand $houseHand
        Give-MoneyToPlayer -player $player -bet $bet -sum $sumPlayer -blackJack $blackJack
        Play-Sound -win
    }

    write-output "Player money $($player.money) $"


    if($player.money -le 0)
    {
        break
    }

}

# Draw-Graph
