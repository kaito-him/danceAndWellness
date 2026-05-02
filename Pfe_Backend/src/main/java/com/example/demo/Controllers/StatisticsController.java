package com.example.demo.Controllers;

import com.example.demo.dto.OverallStatsDTO;
import com.example.demo.services.StatisticsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/statistics")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class StatisticsController {

    private final StatisticsService statisticsService;

    @GetMapping("/overall")
    public ResponseEntity<OverallStatsDTO> getOverallStats() {
        return ResponseEntity.ok(statisticsService.getOverallStats());
    }

    @GetMapping("/today")
    public ResponseEntity<com.example.demo.dto.TodayStatsDTO> getTodayStats() {
        return ResponseEntity.ok(statisticsService.getTodayStats());
    }
}
