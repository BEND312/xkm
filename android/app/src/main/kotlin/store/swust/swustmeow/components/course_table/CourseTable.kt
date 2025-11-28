package store.swust.swustmeow.components.course_table

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import store.swust.swustmeow.entities.CourseCardData
import store.swust.swustmeow.providers.CourseTableDataProvider

@Composable
fun CourseTable(provider: CourseTableDataProvider) {
    val sectionHeight = 54.dp
    val timeColumnWidth = 30.dp
    val weekNum = provider.weekNum

    Box(contentAlignment = Alignment.TopCenter) {
        LazyColumn {
            items(1) { _ ->
                Row(
                    modifier = GlanceModifier.fillMaxSize(),
                    verticalAlignment = Alignment.Vertical.Top
                ) {
                    Column(
                        modifier = GlanceModifier.width(timeColumnWidth),
                        verticalAlignment = Alignment.Vertical.Top
                    ) {
                        for (indexOfDay in 0..5) {
                            Box(
                                modifier = GlanceModifier.height(sectionHeight * 2)
                            ) {
                                CourseTableTimeColumn(
                                    provider = provider,
                                    indexOfDay = indexOfDay,
                                    width = timeColumnWidth,
                                    height = sectionHeight * 2
                                )
                            }
                        }
                    }
                    for (indexOfWeek in 0..6) {
                        Column(
                            modifier = GlanceModifier.defaultWeight(),
                            verticalAlignment = Alignment.Vertical.Top
                        ) {
                            val cards = (0..11).map { indexOfSection ->
                                val section = indexOfSection + 1
                                val matched = provider.entries.filter {
                                    section in it.startSection..it.endSection && it.weekday == indexOfWeek + 1
                                }.sortedBy { it.endWeek }

                                val actives = ArrayList(matched.filter {
                                    it.startWeek <= weekNum && it.endWeek >= weekNum
                                })

                                val display =
                                    if (actives.size > 1) actives.first() else actives.lastOrNull()
                                val hasPrevious = provider.entries.filter {
                                    (section - 1) in it.startSection..it.endSection && it.weekday == indexOfWeek + 1
                                }.any {
                                    it.startWeek <= weekNum && it.endWeek >= weekNum
                                            && it.name == display?.name && it.place == display.place && it.color == display.color
                                }

                                val hasNext = provider.entries.filter {
                                    it.weekday == indexOfWeek + 1
                                }.any {
                                    it.startWeek <= weekNum && it.endWeek >= weekNum && section <= it.startSection
                                }

                                if (display == null) {
                                    CourseCardData(display = true, course = null, hasNext = hasNext)
                                } else if (hasPrevious) {
                                    CourseCardData(
                                        display = false,
                                        course = null,
                                        hasNext = hasNext
                                    )
                                } else {
                                    CourseCardData(
                                        display = true,
                                        course = display,
                                        hasNext = hasNext
                                    )
                                }
                            }

                            for (cardData in cards.filter {
                                it.display || !it.hasNext
                            }) {
                                if (cardData.display && cardData.course == null) {
                                    Column {
                                        Box(
                                            modifier = GlanceModifier.defaultWeight()
                                                .height(sectionHeight + 0.5.dp)
                                        ) {}
                                    }
                                } else if (cardData.display) {
                                    val sections =
                                        cardData.course!!.endSection - cardData.course.startSection + 1
                                    val height = sectionHeight * sections

                                    Box(
                                        contentAlignment = Alignment.TopCenter,
                                        modifier = GlanceModifier.defaultWeight()
                                            .padding(all = 1.dp)
                                            .height(sectionHeight * sections + 1.dp)
                                    ) {
                                        CourseCard(course = cardData.course, height = height)
                                    }
                                }

                                if (!cardData.hasNext) {
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }

//        LazyColumn(modifier = GlanceModifier.fillMaxSize()) {
//            items(6) { indexOfDay ->
//                Row(
//                    modifier = GlanceModifier.fillMaxWidth().height(height),
//                    horizontalAlignment = Alignment.CenterHorizontally,
//                    verticalAlignment = Alignment.CenterVertically
//                ) {
//                    CourseTableTimeColumn(
//                        provider = provider,
//                        indexOfDay = indexOfDay
//                    )
//
//                    Column(modifier = GlanceModifier.defaultWeight().height(height)) {
//                        for (indexOfSection in 0..1) {
//                            Row(modifier = GlanceModifier.fillMaxWidth().height(sectionHeight)) {
//                                for (indexOfWeek in 0..6) {
//                                    val section =
//                                        if (indexOfSection == 0) 2 * (indexOfDay + 1) - 1 else 2 * (indexOfDay + 1)
//                                    val matched = provider.entries.filter {
//                                        section in it.startSection..it.endSection && it.weekday == indexOfWeek + 1
//                                    }.sortedBy { it.endWeek }
//                                    val actives = matched.filter {
//                                        it.startWeek <= weekNum && it.endWeek >= weekNum
//                                    }
//
//                                    val display =
//                                        if (actives.size > 1) actives.first() else actives.lastOrNull()
//
//                                    if (display == null) {
//                                        Box(modifier = GlanceModifier.defaultWeight()) {}
//                                    } else {
//                                        val hasPrevious = provider.entries.filter {
//                                            (section - 1) in it.startSection..it.endSection && it.weekday == indexOfWeek + 1
//                                        }.sortedBy { it.endWeek }.any {
//                                            it.startWeek <= weekNum && it.endWeek >= weekNum
//                                        }
//
//                                        Box(
//                                            contentAlignment = Alignment.Center,
//                                            modifier = GlanceModifier.defaultWeight()
//                                                .padding(all = if (hasPrevious) 0.dp else 1.dp)
//                                        ) {
//                                            CourseCard(course = display, showText = !hasPrevious)
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
    }
}