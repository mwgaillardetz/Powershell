$i = 1

while ($i -le 100) {
    if (($i % 2 -eq 0) -and ($i % 3 -eq 0)) {
        Write-Output "fizzbuzz"
    } elseif ($i % 2 -eq 0) {
        Write-Output "fizz"
    } elseif ($i % 3 -eq 0) {
        Write-Output "buzz"
    } else {
        Write-Output $i
    }
    $i++
}
